# 03_AUTH_CLI_QR_PAIRING_AND_FAST_CAPTURE_API.md
> **TASK 03: ZERO-TRUST AUTH, QR PROVISIONING CLI, `<50ms` CAPTURE, MEDIA STREAMING & DELTA SYNC**
> - **Prerequisites:** Task 02 `[x] PASSED`
> - **Reference Spec:** [`docs/03_api_and_sync_contract.md`](../docs/03_api_and_sync_contract.md) and [`contracts/openapi.json`](../contracts/openapi.json)

---

## 1. Objective
Implement the FastAPI entrypoint, Zero-Trust security middleware (`CF-Access-Client-Id`, `CF-Access-Client-Secret`, and `Authorization: Bearer <token>` SHA-256 device lookup), the provisioning CLI (`app/cli.py` with `register-device --qr`, `revoke-device`, and `seed-persona`), the instant `<50ms` capture endpoints (`/api/v1/capture`, `/api/v1/capture/batch`), binary media upload & HTTP `Range` streaming (`/api/v1/capture/{id}/media`, `/api/v1/media/{asset_id}`), and monotonic delta sync (`/api/v1/sync/delta`).

---

## 2. Exact Files to Create

1. `server/app/core/security.py`
2. `server/app/cli.py`
3. `server/app/schemas/__init__.py`
4. `server/app/schemas/capture.py`
5. `server/app/schemas/sync.py`
6. `server/app/api/__init__.py`
7. `server/app/api/v1/__init__.py`
8. `server/app/api/v1/capture.py`
9. `server/app/api/v1/media.py`
10. `server/app/api/v1/sync.py`
11. `server/app/main.py`
12. `server/tests/__init__.py`
13. `server/tests/test_task_03_capture_sync.py`

---

## 3. Step-by-Step Implementation Instructions

### Step 3.1: Implement Zero-Trust Auth Dependency (`server/app/core/security.py`)
- Verify `CF-Access-Client-Id` and `CF-Access-Client-Secret` headers when `settings.ENFORCE_CF_HEADERS` is enabled (and always require `Authorization: Bearer <token>`).
- Hash the Bearer token with `hashlib.sha256(token.encode()).hexdigest()`, query `devices` where `api_key_hash == token_hash` and `is_revoked == False`.
- Update `device.last_sync_at` and return the authenticated `Device` model; raise `HTTPException(status_code=401)` otherwise.

### Step 3.2: Implement Provisioning & QR Pairing CLI (`server/app/cli.py`)
Implement `argparse` / `typer` commands matching `docs/03_api_and_sync_contract.md` Section 1.3:
- `register-device --name <str> --type <str> [--qr]`:
  - Generates `raw_token = f"mem_live_{secrets.token_hex(32)}"`.
  - Stores `sha256(raw_token)` in `devices`.
  - Builds the JSON pairing bundle (`v`, `api_base_url`, `cf_access_client_id`, `cf_access_client_secret`, `device_id`, `bearer_key`, `ntfy_url`, `ntfy_topic`, `ntfy_token`).
  - When `--qr` is passed, renders an ASCII QR code to stdout using `qrcode.QRCode()` (`qr.print_ascii(invert=True)`) alongside the JSON string.
- `revoke-device --device-id <uuid>`: Sets `is_revoked = True`.
- `seed-persona [--file <path>]`: Validates against `../contracts/persona.schema.json`, pads the rendered `cached_prompt_prefix` to $\ge 1,024$ tokens (at least `4,200` characters) using the static system prompt + persona snapshot + project index template from `docs/06_luna_6_persona_and_spark_engine.md`, and inserts `version_number = 1, is_current = True` into `persona_snapshots`.

### Step 3.3: Implement Fast Capture & Media Endpoints (`capture.py` & `media.py`)
- `POST /api/v1/capture` (`HTTP 202 Accepted`):
  - Uses PostgreSQL `insert(Capture).values(...).on_conflict_do_nothing(index_elements=["id"])` for strict UUIDv7 idempotency.
  - If `reading_session_id` is omitted but an active `ReadingSession` exists and `capture_type == 'book_scan'`, links `reading_session_id` automatically.
  - Enqueues `job_ingest_capture(capture_id)` via a lightweight Redis enqueue call (gracefully no-oping if worker broker is mocked in unit tests) and returns `{ "status": "ACCEPTED", "id": ..., "processing_status": "QUEUED", "sync_version": ... }`.
- `POST /api/v1/capture/batch` (`HTTP 202 Accepted`): Upserts up to 50 items idempotently in one transaction.
- `POST /api/v1/capture/{capture_id}/media` (`HTTP 201 Created`):
  - Streams uploaded file to `{settings.MEDIA_ROOT}/{YYYY}/{MM}/{capture_id}/{asset_id}.{ext}`, computes SHA-256 on the fly, verifies it matches `sha256_checksum` (returns `400 Bad Request` on mismatch), inserts `MediaAsset` (`page_order`, `soft_token_budget`), and returns `201`.
- `GET /api/v1/media/{asset_id}`:
  - Streams file with `ETag: "<sha256_checksum>"` and `Cache-Control: private, max-age=31536000, immutable`.
  - Parses `Range: bytes=start-end` header and returns `HTTP 206 Partial Content` with `Content-Range` when requested.

### Step 3.4: Implement Delta Sync (`server/app/api/v1/sync.py`)
- `GET /api/v1/sync/delta?since_version={int}&limit=200`:
  - Queries `captures` (with joined `media_assets` and `capture_annotations`), `ai_sparks` (with `source_capture_ids` from `document_links`), `reminders`, and `reading_sessions` where `sync_version > since_version`.
  - Computes `current_max_sync_version` across the returned tables and returns the structured delta response.

---

## 4. Deterministic Verification Gate (`PASS / FAIL`)

Write `server/tests/test_task_03_capture_sync.py` covering:
1. `app.cli register-device --qr` and `seed-persona` execution.
2. Rejecting unauthenticated requests (`401 Unauthorized`).
3. `POST /api/v1/capture` returning `202 Accepted`, and verifying that sending the **exact same UUIDv7 twice** returns `202 Accepted` without creating a duplicate row in `captures`.
4. `POST /api/v1/capture/{id}/media` verifying SHA-256 checksum validation and `GET /api/v1/media/{asset_id}` returning `206 Partial Content` on a `Range: bytes=0-15` header.
5. `GET /api/v1/sync/delta?since_version=0` returning the newly created capture and its `media_assets`.

Run:
```powershell
cd server
uv run ruff check .
uv run mypy app
uv run pytest tests/test_task_03_capture_sync.py -v
```
- **Success Criteria:** `0` lint/type errors and `5 passed` in pytest (exit code `0`). Mark **Task 03** as `[x] PASSED` in `tasks/00_TASK_RUNNER_AND_INDEX.md`.
