# 03_API_AND_SYNC_CONTRACT.md
> **REST API, MULTIPART UPLOAD & DELTA SYNC PROTOCOL SPECIFICATION**
> This document defines all HTTP endpoints, security headers, Pydantic v2 DTOs, and conflict-free delta synchronization protocols between the Edge Clients (`Flutter` & `WXT Extension`) and the `FastAPI` Home Server.

---

## 1. Zero-Trust Edge Security & Authentication Contract

Every HTTP or WebSocket request traversing the Cloudflare Tunnel (`https://api.<your-domain>.com`) MUST include three mandatory headers. Requests missing the Cloudflare Access headers are dropped at Cloudflare's edge (Zone 2) before reaching the home network.

### 1.1 Mandatory Request Headers
```http
CF-Access-Client-Id: <cloudflare_service_token_id>
CF-Access-Client-Secret: <cloudflare_service_token_secret>
Authorization: Bearer <device_scoped_api_key>
X-Client-Device-Id: <uuid_of_registered_device>
```

### 1.2 FastAPI Verification Dependency (`app/core/security.py`)
1. Extract `Authorization: Bearer <token>`.
2. Compute `SHA-256(token)` and query `devices` table where `api_key_hash = :hash AND is_revoked = FALSE`.
3. Update `devices.last_sync_at = NOW()` asynchronously.
4. If invalid or revoked, immediately return `HTTP 401 Unauthorized`.

### 1.3 Device Provisioning, QR Pairing & Initial Bootstrap CLI (`app/cli.py`)
Because this is a single-tenant private context engine, device credentials and initial persona state are provisioned via the server CLI (`app/cli.py`):
- **Register a Device with Instant QR Onboarding (`register-device --qr`):**
  ```bash
  uv run python -m app.cli register-device --name "Pixel-9a" --type android --qr
  ```
  Generates a cryptographically random 256-bit Bearer token (`mem_live_<64_hex_chars>`), inserts its `SHA-256` digest into `devices.api_key_hash`, and renders an **ASCII QR code directly in the terminal** (plus raw JSON fallback) containing the complete zero-typing connection bundle:
  ```json
  {
    "v": 1,
    "api_base_url": "https://api.yourdomain.com",
    "cf_access_client_id": "<token_id>.access",
    "cf_access_client_secret": "<token_secret>",
    "device_id": "d4e5f6a7-...",
    "bearer_key": "mem_live_...",
    "ntfy_url": "https://api.yourdomain.com/ntfy",
    "ntfy_topic": "scratchpad_alerts",
    "ntfy_token": "tk_..."
  }
  ```
  Scanning this QR code in the Flutter onboarding screen configures `flutter_secure_storage` in 1 second with zero manual typing.
- **Revoke a Device (`revoke-device`):**
  ```bash
  uv run python -m app.cli revoke-device --device-id <uuid>
  ```
  Sets `devices.is_revoked = TRUE`.
- **Seed Initial Persona (`seed-persona`):**
  ```bash
  uv run python -m app.cli seed-persona --file ./contracts/initial_persona.json
  ```
  Validates the JSON against `contracts/persona.schema.json`, renders the initial `cached_prompt_prefix` ($\ge 1,024$ tokens), and inserts `version_number = 1, is_current = TRUE` into `persona_snapshots`.

---

## 2. Fast Capture & Media Upload Endpoints (`/api/v1/capture`)

### 2.1 `POST /api/v1/capture` — Single Instant Capture (`<50ms` SLA)
Used by the WXT Browser Extension and Flutter app for text notes, URLs, and highlights. Must be strictly idempotent using client-generated `UUIDv7`.

**Request Payload (`application/json`):**
```json
{
  "id": "0192d04e-7b2a-7000-814f-9f0c8d1a2b3c",
  "capture_type": "video_reel",
  "title": "Zero Trust DNS Architecture Reel",
  "raw_text": "Check how he configures unbound with cloudflared #homelab #dns",
  "source_url": "https://www.instagram.com/reel/Cxyz12345/",
  "user_tags": ["homelab", "dns"],
  "captured_at": "2026-10-28T03:15:00Z",
  "dom_fallback_markdown": null
}
```

**Server Action:**
1. Execute `INSERT INTO captures (...) VALUES (...) ON CONFLICT (id) DO NOTHING RETURNING id, sync_version`.
2. Enqueue `job_ingest_capture(capture_id=id)` into Redis (`Taskiq`).
3. Return `HTTP 202 Accepted`.

**Response (`202 Accepted`):**
```json
{
  "status": "ACCEPTED",
  "id": "0192d04e-7b2a-7000-814f-9f0c8d1a2b3c",
  "processing_status": "QUEUED",
  "sync_version": 1042
}
```

---

### 2.2 `POST /api/v1/capture/batch` — Offline Outbox Batch Flush
Used when a client comes back online and flushes up to 50 queued captures in a single transaction.

**Request Payload:**
```json
{
  "items": [
    {
      "id": "0192d04e-7b2a-7000-814f-9f0c8d1a2b3c",
      "capture_type": "text_note",
      "title": null,
      "raw_text": "Idea: use Matryoshka 256d slice only if we ever need mobile local vector cache",
      "source_url": null,
      "user_tags": ["architecture"],
      "captured_at": "2026-10-28T02:10:11Z"
    }
  ]
}
```

**Response (`202 Accepted`):**
```json
{
  "accepted_ids": ["0192d04e-7b2a-7000-814f-9f0c8d1a2b3c"],
  "highest_sync_version": 1043
}
```

---

### 2.3 `POST /api/v1/capture/{capture_id}/media` — Multipart Binary Upload
Used for book page scans (`book_scan`), image uploads (`image_upload`), and voice memos (`audio_memo`).

**Request (`multipart/form-data`):**
- `asset_id`: Client-generated `UUIDv7`
- `media_kind`: `'image' | 'book_page' | 'audio'`
- `soft_token_budget`: `280` (standard image) or `1120` (dense book scan)
- `sha256_checksum`: 64-character hex string
- `file`: Binary stream

**Server Action:**
1. Stream binary to `/data/media/{YYYY}/{MM}/{capture_id}/{asset_id}.{ext}` while verifying `sha256_checksum`.
2. Insert row into `media_assets`.
3. Trigger `job_ingest_capture(capture_id)` in Redis.
4. Return `HTTP 201 Created`.

---

### 2.4 `GET /api/v1/media/{asset_id}` — Authenticated Media Streaming & Cross-Device Cache
Allows secondary devices (e.g., Desktop app viewing a book scan captured on Android, or Mobile playing back a scraped Reel/audio memo) to fetch and cache local media assets stored in `/data/media/`.

- **Headers Required:** Standard Zero-Trust headers (`CF-Access-Client-Id`, `CF-Access-Client-Secret`, `Authorization: Bearer <token>`).
- **Query Params:** `?variant=original|thumbnail` (defaults to `original`; `thumbnail` serves a fast WebP preview for images/videos).
- **Behavior:**
  - Looks up `media_assets` by `id = asset_id` and verifies the file exists on `/data/media/{local_rel_path}`.
  - Supports HTTP `Range: bytes=...` (`HTTP 206 Partial Content`) for smooth video/audio seeking.
  - Returns `ETag: "<sha256_checksum>"` and `Cache-Control: private, max-age=31536000, immutable` so clients cache downloaded media permanently by checksum.

---

## 3. Delta Synchronization Protocol (`/api/v1/sync`)

Because `captures` are append-only (`user_raw` text is immutable) and `sync_version` is a monotonically increasing global sequence across `captures`, `ai_sparks`, and `reminders`, delta sync is deterministic and lock-free.

### 3.1 `GET /api/v1/sync/delta?since_version={int}&limit=200`
Returns all records created or updated on the server after `since_version` (including OCR/transcript completions, newly sparked AI documents, and reminders).

**Response (`200 OK`):**
```json
{
  "current_max_sync_version": 1089,
  "has_more": false,
  "captures": [
    {
      "id": "0192d04e-7b2a-7000-814f-9f0c8d1a2b3c",
      "capture_type": "video_reel",
      "processing_status": "SPARK_EVALUATED",
      "title": "Zero Trust DNS Architecture Reel",
      "raw_text": "Check how he configures unbound with cloudflared #homelab #dns",
      "source_url": "https://www.instagram.com/reel/Cxyz12345/",
      "extracted_title": "Unbound + Cloudflared Split-Horizon DNS",
      "extracted_markdown": null,
      "ocr_text": "unbound.conf: interface: 127.0.0.1@5335",
      "transcript_text": "In this setup we bind Unbound to port 5335 and route upstream over DoH...",
      "user_tags": ["homelab", "dns"],
      "auto_tags": ["networking", "unbound", "cloudflare"],
      "media_assets": [
        {
          "id": "0192d04e-8899-7000-8000-aabbccddeeff",
          "media_kind": "video",
          "mime_type": "video/mp4",
          "file_size_bytes": 14520192,
          "sha256_checksum": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
          "duration_seconds": 42.5,
          "width_px": 720,
          "height_px": 1280
        }
      ],
      "captured_at": "2026-10-28T03:15:00Z",
      "updated_at": "2026-10-28T03:15:18Z",
      "is_archived": false,
      "is_deleted": false,
      "sync_version": 1085
    }
  ],
  "ai_sparks": [
    {
      "id": "c84d91a0-41e2-4f9b-9c12-71a098bc1234",
      "title": "Connecting Split-Horizon DNS to Your Home Lab Tunnel",
      "spark_markdown": "## Synthesis\nYour recent Reel capture on `Unbound` directly solves the local resolution latency issue you noted in...",
      "spark_rationale": "Matched capture 0192d04e with your active project 'Home-Server-Zero-Trust' (similarity: 0.84).",
      "related_project": "home-server-zero-trust",
      "tags": ["homelab", "dns", "architecture"],
      "source_capture_ids": [
        "0192d04e-7b2a-7000-814f-9f0c8d1a2b3c",
        "0192c110-1122-7000-9abc-001122334455"
      ],
      "is_read": false,
      "is_pinned": false,
      "created_at": "2026-10-28T03:15:22Z",
      "sync_version": 1088
    }
  ],
  "reminders": [
    {
      "id": "f1234567-89ab-4cde-8012-3456789abcde",
      "target_id": "c84d91a0-41e2-4f9b-9c12-71a098bc1234",
      "target_table": "ai_sparks",
      "reminder_type": "CONTEXTUAL_MATCH",
      "title": "New AI Spark: Split-Horizon DNS",
      "message": "Luna connected your DNS Reel to 2 earlier homelab notes.",
      "deep_link_uri": "scratchpad://spark/c84d91a0-41e2-4f9b-9c12-71a098bc1234",
      "scheduled_for": "2026-10-28T09:00:00Z",
      "is_acknowledged": false,
      "sync_version": 1089
    }
  ]
}
```

---

## 4. Multimodal Semantic Search & "Ask Memoria" Endpoints (`/api/v1/search`)

### 4.1 `POST /api/v1/search` — Hybrid RRF Retrieval
Executes the Hybrid RRF (`google/embeddinggemma-2` `SearchQuery` vector + PostgreSQL `tsvector` BM25) + Persona Project Boost.

**Request Payload:**
```json
{
  "query": "book page about memory allocation or garbage collection",
  "top_k": 15,
  "min_similarity": 0.45,
  "filter_types": ["book_scan", "pdf_document", "text_note", "ai_spark"],
  "include_archived": false
}
```

**Response (`200 OK`):**
```json
{
  "query_time_ms": 28.4,
  "results": [
    {
      "item_id": "0192b881-3a12-7000-8001-123456789abc",
      "item_table": "captures",
      "item_type": "book_scan",
      "modality_composition": "book_page",
      "title": "Crafting Interpreters - Ch 26 Garbage Collection",
      "snippet": "...mark-sweep collector pauses execution when heap threshold is crossed...",
      "semantic_similarity": 0.812,
      "keyword_score": 0.441,
      "rrf_score": 0.0158,
      "item_timestamp": "2026-10-25T18:20:00Z"
    }
  ]
}
```

### 4.2 `POST /api/v1/search/ask` — On-Demand Conversational RAG ("Ask Memoria")
Executes the Hybrid RRF search (`top_k = 10`) and passes the scrubbed text snippets to `gpt-6-luna` behind the cached `Message[0]` persona prefix to answer a complex question across the user's memory with inline `[capture_id]` citations.
- **Request:** `{ "question": "What were the 3 trade-offs I noted about split-horizon DNS?", "save_as_spark": false }`
- **Response (`200 OK`):** `{ "answer_markdown": "...", "cited_items": [...], "follow_up_questions": [...], "created_spark_id": null }`

---

## 5. Mutations, Annotations, Reading Sessions, Triage & Rescue

### 5.1 Append-Only Marginalia & Metadata (`captures`, `sparks`, `reminders`)
While `raw_text` is immutable, users can append thread notes (`capture_annotations`), archive items, add tags, pin `ai_sparks`, or snooze/acknowledge reminders:
- `POST /api/v1/captures/{id}/annotations` -> `{ "id": "<uuidv7>", "content": "Update: tested on kernel 6.11 and it works." }` (Appends row to `capture_annotations`, updates `captures.annotations_concat`, and re-indexes parent embedding).
- `PATCH /api/v1/captures/{id}/meta` -> `{ "user_tags": [...], "reading_session_id": "<uuid>", "page_range": "pp. 42-44", "is_archived": true }`
- `PATCH /api/v1/sparks/{id}/state` -> `{ "is_read": true, "is_pinned": true, "is_dismissed": false }`
- `PATCH /api/v1/reminders/{id}/ack` -> `{ "is_acknowledged": true, "snoozed_until": null }`

### 5.2 Sticky Book / Reading Sessions (`/api/v1/reading-sessions`)
Allows pinning an active book or course so consecutive 1-tap camera burst scans automatically inherit the book's title, author, and `#book` tags:
- `POST /api/v1/reading-sessions` -> `{ "id": "<uuidv7>", "source_title": "Crafting Interpreters", "author": "Robert Nystrom", "default_tags": ["book", "compilers"] }`
- `GET /api/v1/reading-sessions/active` -> Returns the active session(s).
- `PATCH /api/v1/reading-sessions/{id}` -> `{ "is_active": false }` (ends session).

### 5.3 Intentional Spark Synthesis (`POST /api/v1/sparks/synthesize`)
Allows the user to select $\ge 2$ captures (or search results) and explicitly trigger `gpt-6-luna` to synthesize them into a new `ai_spark`:
- **Request:** `{ "capture_ids": ["<uuid1>", "<uuid2>"], "user_angle": "Compare these two approaches for our home lab" }`

### 5.4 Daily / Weekly Review Triage Deck (`/api/v1/triage`)
Prevents the scratchpad from becoming a write-only graveyard and feeds explicit positive/negative signals into the nightly `persona.json` cron:
- `GET /api/v1/triage/deck?limit=20` -> Returns unreviewed `captures` (`is_triage_reviewed = FALSE`) and unread `ai_sparks` (`is_read = FALSE`) from the last 7 days.
- `POST /api/v1/triage/{item_id}/decision` -> `{ "item_table": "captures", "action": "KEEP" | "PIN_TO_PROJECT" | "ARCHIVE" | "DISMISS", "project_slug": "home-server-zero-trust" }`

### 5.5 Browser Cookie Sync & `EXTRACTION_PARTIAL` Rescue (`/api/v1/scraper`)
- `POST /api/v1/scraper/cookies` -> Uploaded by the WXT Browser Extension; writes scoped Netscape cookie lines (`instagram.com`, `youtube.com`, `x.com`) to `/data/media/.cookies/cookies.txt` (`chmod 600`) for `yt-dlp`.
- `GET /api/v1/captures/partial` -> Lists mobile-shared URLs stuck in `EXTRACTION_PARTIAL`.
- `POST /api/v1/captures/{id}/rescue` -> `{ "extracted_title": "...", "dom_fallback_markdown": "..." }` (Pushed by WXT extension after loading the page in the authenticated desktop browser; re-triggers `job_ingest_capture(id)`).

### 5.6 Markdown / Obsidian Vault Export (`/api/v1/export`)
Graduates mature `ai_sparks` and `captures` into local Markdown folders or Obsidian vaults with YAML frontmatter and `[[wiki-links]]`:
- `GET /api/v1/sparks/{id}/export.md` -> Returns a formatted `.md` file with YAML frontmatter (`id`, `title`, `created_at`, `tags`, `related_project`, `sources`) and inline `[[capture_id|Title]]` backlinks plus verbatim source quotes.
- `GET /api/v1/export/markdown?since_version={int}` -> Returns a JSON bundle or `.tar.gz` of newly created/updated `.md` files for automated local folder sync on Desktop.

---

## 6. Persona & Spark Graph Endpoints (`/api/v1/persona` & `/api/v1/sparks`)

### 6.1 `GET /api/v1/persona` — Fetch Current Persona State
Returns the active `persona_snapshots` row (`is_current = TRUE`) so the user can inspect how `gpt-6-luna` currently models their active projects, learning threads, and spark thresholds.

**Response (`200 OK`):**
```json
{
  "version_number": 14,
  "persona_json": {
    "schema_version": "1.0",
    "core_domains": ["systems-architecture", "self-hosted-infra", "flutter", "applied-ml"],
    "active_projects": [
      {
        "slug": "home-server-zero-trust",
        "name": "Home Server Zero Trust",
        "focus_summary": "Hardening Cloudflare Tunnel, Unbound DNS, and local multimodal RAG",
        "priority_weight": 1.6,
        "last_active_date": "2026-10-28"
      }
    ],
    "current_learning_threads": [
      {
        "topic": "Multimodal Vector Indexing",
        "recent_questions": ["How to balance soft token budgets for dense book scans?"],
        "depth_level": "deep_dive"
      }
    ],
    "synthesis_preferences": {
      "spark_threshold": 0.72,
      "preferred_style": "concise architectural synthesis with concrete trade-offs"
    },
    "ignored_or_archived_topics": ["legacy-webpack-configs"]
  },
  "summary_diff": "Increased priority_weight on home-server-zero-trust from 1.3 to 1.6 after 4 related DNS/tunnel captures.",
  "created_at": "2026-10-28T03:00:04Z"
}
```

### 6.2 `PUT /api/v1/persona` — Manual Persona Override
Allows the user to explicitly edit their `persona_json` (e.g., adding a new active project, archiving an old topic, or tuning `spark_threshold`).
- Validates payload against `contracts/persona.schema.json`.
- Renders a new deterministic `cached_prompt_prefix` ($\ge 1,024$ tokens), marks the previous snapshot `is_current = FALSE`, and inserts `version_number = prev + 1`.

### 6.3 `POST /api/v1/persona/reflect` — Trigger Immediate Reflection
Enqueues `job_nightly_persona_reflection` on demand and returns `HTTP 202 Accepted`.

### 6.4 `GET /api/v1/sparks/{id}` — Spark Detail & Bidirectional Graph Links
Returns the `ai_spark` document along with its resolved `document_links` (`SPARK_SOURCE`, `SEMANTIC_RELATED`, `USER_MANUAL_LINK`, `THREAD_CONTINUATION`) and summary cards of all linked `captures`.