# 00_TASK_RUNNER_AND_INDEX.md
> **MASTER EXECUTION PROTOCOL & DETERMINISTIC STATE TRACKER FOR CODING AGENTS**
> This file is the single source of truth for building **Memoria v3** step-by-step using a coding agent (including smaller or faster models).
> **READ THIS ENTIRE FILE BEFORE EXECUTING ANY TASK IN `/tasks`.**

---

## 1. Strict Operating Protocol for Smaller Models

1. **Sequential Execution Only:**
   - Never start Task `N+1` until Task `N` has status `[x] PASSED` in the Master Task Table below.
   - Read only the current task file (`tasks/0X_*.md`) and the specific reference doc (`docs/0X_*.md`) cited in that task's header to keep your context window clean and focused.
2. **Zero Placeholders / Anti-Elision Rule:**
   - Never write `# TODO`, `pass`, `// ... existing code ...`, or stubbed functions. Every file listed in a task's **"Files to Create / Update"** section must be written completely with full imports and strict type annotations.
3. **Deterministic Verification Gate (Mandatory):**
   - Every task ends with a **Deterministic Verification Gate** containing exact shell commands and automated tests.
   - A task is **ONLY** complete when every verification command exits with code `0` (`PASS`) and prints the expected verification string.
   - If a verification command fails (`exit code != 0`), **DO NOT** mark the task as passed and **DO NOT** move to the next task. Fix the error, re-run the verification gate until it exits `0`, or ask the user if blocked by hardware/credentials.
4. **Human-in-the-Loop (`[USER INTERVENTION REQUIRED]`) Checkpoints:**
   - Whenever a task reaches a `[USER INTERVENTION REQUIRED]` block (e.g., filling API keys in `.env`, accepting gated HuggingFace weights, creating a Cloudflare Tunnel token, or scanning a QR code on a phone), **STOP calling tools**, change the task status in this file to `[-] WAITING_FOR_USER`, and display the exact prompt box from the task file to the user.

---

## 2. Master Task State Table

Update the `Status` column in this table as each task is verified (`[ ] PENDING` -> `[~] IN_PROGRESS` -> `[-] WAITING_FOR_USER` -> `[x] PASSED`):

| ID | Task File | Scope Summary | User Intervention? | Deterministic Verification Command | Status |
|---|---|---|---|---|---|
| **01** | [`tasks/01_INFRA_POSTGRES_REDIS_AND_ENV.md`](./01_INFRA_POSTGRES_REDIS_AND_ENV.md) | Docker Compose (`postgres-pgvector`, `redis`, `ntfy`, `cloudflared`), `init.sql`, `.env` setup | **YES** (GPU check + `.env` secrets) | `docker compose -f infra/docker-compose.yml exec -T postgres psql -U scratchpad -d scratchpad_db -c "SELECT extname FROM pg_extension"` | `[x] PASSED` |
| **02** | [`tasks/02_BACKEND_SCAFFOLD_ORM_AND_ALEMBIC.md`](./02_BACKEND_SCAFFOLD_ORM_AND_ALEMBIC.md) | `/server` `uv` setup, SQLAlchemy/SQLModel 10 tables, triggers, `VECTOR(768)` HNSW index & Alembic | No | `cd server && uv run ruff check . && uv run mypy app && uv run alembic upgrade head && uv run python scripts/verify_task_02.py` | `[x] PASSED` |
| **03** | [`tasks/03_AUTH_CLI_QR_PAIRING_AND_FAST_CAPTURE_API.md`](./03_AUTH_CLI_QR_PAIRING_AND_FAST_CAPTURE_API.md) | Zero-Trust auth middleware, `app/cli.py` (`--qr` pairing), `<50ms` `/capture`, `/media` Range stream & `/sync/delta` | No | `cd server && uv run ruff check . && uv run mypy app && uv run pytest tests/test_task_03_capture_sync.py -v` | `[x] PASSED` |
| **04** | [`tasks/04_EMBEDDING_GEMMA2_AND_HYBRID_SEARCH.md`](./04_EMBEDDING_GEMMA2_AND_HYBRID_SEARCH.md) | `embedder.py` (`google/embeddinggemma-2` in `bfloat16`/`float32`, `768d`, Redis GPU mutex) & Hybrid RRF `/search` | **YES** (Verify `HF_TOKEN` gated model access) | `cd server && uv run ruff check . && uv run mypy app && uv run pytest tests/test_task_04_embedder_search.py -v` | `[x] PASSED` |
| **05** | [`tasks/05_MULTIMODAL_SCRAPER_OCR_WHISPER_AND_WORKERS.md`](./05_MULTIMODAL_SCRAPER_OCR_WHISPER_AND_WORKERS.md) | Taskiq queues, `scraper.py` (`trafilatura`, `PyMuPDF`, `yt-dlp` + `?t=` clip + cookies, `PaddleOCR`, `faster-whisper`) & Rescue API | No | `cd server && uv run ruff check . && uv run mypy app && uv run pytest tests/test_task_05_scraper_workers.py -v` | `[x] PASSED` |
| **06** | [`tasks/06_LUNA6_SPARK_ENGINE_ASK_MEMORIA_AND_TRIAGE.md`](./06_LUNA6_SPARK_ENGINE_ASK_MEMORIA_AND_TRIAGE.md) | `luna_agent.py` (cached `persona.json` prefix, sparks, voice distillation, Ask Memoria RAG), annotations, reading sessions, triage & vault export | No | `cd server && uv run ruff check . && uv run mypy app && uv run pytest tests/test_task_06_luna_workflows.py -v` | `[x] PASSED` |
| **07** | [`tasks/07_NTFY_REMINDER_TRIAGE_AND_CLOUDFLARE_TUNNEL.md`](./07_NTFY_REMINDER_TRIAGE_AND_CLOUDFLARE_TUNNEL.md) | `notifier.py` (3/day budget, quiet hours bundler, `ntfy` publisher), full Docker build & `cloudflared` tunnel | **YES** (Cloudflare Tunnel & Access Service Token) | `cd server && uv run pytest tests/test_task_07_notifier.py -v && docker compose -f ../infra/docker-compose.yml ps` | `[x] PASSED` |
| **08** | [`tasks/08_WXT_BROWSER_EXTENSION.md`](./08_WXT_BROWSER_EXTENSION.md) | `/extension` WXT MV3 Preact clipper, `@mozilla/readability`, offline outbox, cookie sync & Rescue Queue badge | **YES** (Load unpacked extension in browser) | `cd extension && pnpm tsc --noEmit && pnpm wxt build` | `[x] PASSED` |
| **09** | [`tasks/09_FLUTTER_DATA_LAYER_DRIFT_AND_SYNC.md`](./09_FLUTTER_DATA_LAYER_DRIFT_AND_SYNC.md) | `/app_client` scaffold, 6 Drift SQLite tables, Dio Zero-Trust client, `OutboxFlusher` & `NtfyListenerService` | No | `cd app_client && dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test test/task_09_sync_test.dart` | `[x] PASSED` |
| **10** | [`tasks/10_FLUTTER_UI_SCREENS_AND_E2E_VERIFICATION.md`](./10_FLUTTER_UI_SCREENS_AND_E2E_VERIFICATION.md) | All 6 Flutter screens (QR onboarding, scratchpad + book burst scanner, sparks + export, Ask Memoria search, triage deck, share sheet) | **YES** (Scan QR code & run 5-step E2E smoke test) | `cd app_client && flutter analyze && flutter test test/task_10_ui_test.dart` | `[x] PASSED` |

---

## 3. How to Prompt a Smaller Model Using This Folder

To run any step with a smaller coding model, give it this exact prompt:

> *"Read `AGENTS.md` and `tasks/00_TASK_RUNNER_AND_INDEX.md`. Find the first task that is not `[x] PASSED`, read its task file in `/tasks`, execute every step without placeholders, run its Deterministic Verification Gate until it exits 0, and stop at any `[USER INTERVENTION REQUIRED]` checkpoint."*
