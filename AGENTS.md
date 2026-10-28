# 00_AGENT_RULES_AND_MONOREPO.md
> **ROOT SYSTEM DIRECTIVE FOR CODING AGENTS (`AGENTS.md` / `.cursorrules`)**
> Read this entire file before planning, writing, refactoring, or executing any code in this repository. All architectural invariants and model rules defined below are strictly non-negotiable.

---

## 1. System Identity & Core Philosophy
We are building a **Self-Hosted Personal Context, Scratchpad, and Multimodal Ingestion Engine**.
- **Not a generic note-taking app:** It is a fast capture scratchpad and asynchronous context engine that ingests thoughts, URLs, articles, technical PDFs, short-form videos (Reels/Shorts), long-form timestamped YouTube clips, audio memos, and multi-page scanned book sessions across all user devices.
- **Privacy & Compute Split:**
  - **Edge Clients (Flutter Mobile/Desktop + WXT Browser Extension):** Local-first capture using offline outbox queues, 1-scan QR code device onboarding, active reading sessions for book scanning, and a daily triage deck.
  - **Home Server (Local Privacy Zone):** Exposes API via Cloudflare Tunnel protected by Zero Trust Service Tokens. Runs PostgreSQL 16 (`pgvector`), media scraping (`yt-dlp` with browser-extension cookie sync & timestamp range clipping), PDF extraction (`PyMuPDF`), local OCR (`PaddleOCR` / `Tesseract`), local audio transcription (`faster-whisper`), and **`google/embeddinggemma-2`** for unified multimodal vector indexing. Raw media files never leave the home server.
  - **Cloud Synthesis Worker (`gpt-6-luna`):** Called strictly with scrubbed text snippets and a cached `persona.json` prefix to quietly update user persona state, distil rambling voice memos into action items, power on-demand **"Ask Memoria"** conversational RAG, and generate non-destructive **Linked Idea Spark Documents** (`ai_spark`).

---

## 2. Locked Technology Stack

### A. Backend & AI Pipeline (`/server`)
- **Language & Runtime:** Python `>=3.12`, strictly managed via **`uv`** (`pyproject.toml` + `uv.lock`). Never use raw `pip` or `poetry`.
- **Web Framework:** **FastAPI** (async endpoints only, Pydantic v2 strict validation).
- **Database & ORM:** **PostgreSQL 16** with **`pgvector`** extension. ORM: **SQLAlchemy 2.0 (Async)** + **SQLModel** + **Alembic** for migrations.
- **Async Job Queue:** **Taskiq** (or **ARQ**) backed by **Redis 7** for non-blocking media scraping, OCR, embedding generation, and LLM synthesis.
- **Multimodal Embedding Engine:** **`google/embeddinggemma-2`** (740M parameters, Gemma 4 architecture) via `sentence-transformers` / `transformers` + `torch`.
- **Media & Text Extraction:** `yt-dlp` (Reels/Shorts/timestamped video clips + cookie-jar sync), `faster-whisper` (audio-to-text), `trafilatura` (article extraction), `pymupdf` (`fitz` for technical PDFs), and `paddleocr` / `pytesseract` (book pages & images).
- **Cloud Reasoning LLM:** OpenAI API using model ID **`gpt-6-luna`** (`$0.10/1M` input, `$0.50/1M` output, `90%` cached input discount).
- **Push Notification Broker:** Self-hosted **`ntfy`** server container (`binwiederhier/ntfy`).

### B. Cross-Platform Client (`/app_client`)
- **Framework:** **Flutter** (Dart 3.x) targeting **Android**, **Linux Desktop**, and **Windows**.
- **State Management:** **Riverpod** (`flutter_riverpod` + `riverpod_annotation` with code generation).
- **Local Offline Database:** **Drift** (reactive SQLite wrapper) storing local scratchpad state, cached AI sparks, and the `outbox_sync_queue` table.
- **OS Integrations:**
  - Share sheet ingestion (`receive_sharing_intent`).
  - Direct `ntfy` WebSocket/SSE stream consumer + `flutter_local_notifications` + Android `WorkManager` periodic background sync.

### C. Browser Capture Extension (`/extension`)
- **Framework:** **WXT** (Next-gen Web Extension framework, Manifest V3, TypeScript) managed via **`pnpm`**.
- **UI:** Lightweight **Preact** + **Tailwind CSS** popup and context-menu clipper.
- **Storage:** `browser.storage.local` / IndexedDB outbox queue so captures succeed even if the tunnel is temporarily unreachable.

### D. Infrastructure & Security (`/infra`)
- **Container Orchestration:** **Docker Compose** (`postgres-pgvector`, `redis`, `server-api`, `server-worker`, `ntfy`, `cloudflared`).
- **Edge Security:** **Cloudflare Tunnel (`cloudflared`)** + **Cloudflare Access Service Tokens** (`CF-Access-Client-Id` and `CF-Access-Client-Secret`) + application-level scoped Bearer API keys.

---

## 3. Monorepo Directory Structure

```text
/
├── AGENTS.md                        # Symlink or copy of 00_AGENT_RULES_AND_MONOREPO.md
├── docs/                            # Architectural & implementation specification suite (00 to 09, mirrored at root)
│   ├── 00_AGENT_RULES_AND_MONOREPO.md
│   ├── 01_ARCHITECTURE_AND_DATA_FLOW.md
│   ├── 02_DATABASE_AND_VECTOR_SCHEMA.md
│   ├── 03_api_and_sync_contract.md
│   ├── 04_ingestion_and_media_pipeline.md
│   ├── 05_embeddinggemma_2_implementation_spec.md
│   ├── 06_luna_6_persona_and_spark_engine.md
│   ├── 07_reminder_triage_and_push_notification_spec.md
│   ├── 08_client_and_browser_extension_specs.md
│   └── 09_infrastructure_and_cloudflare_tunnel_deployment.md
├── contracts/                       # Shared OpenAPI 3.1 spec & JSON Schemas
│   ├── openapi.json
│   └── persona.schema.json
├── server/                          # Python 3.12 FastAPI + Worker + ML Service
│   ├── pyproject.toml
│   ├── uv.lock
│   ├── alembic/
│   └── app/
│       ├── main.py                  # FastAPI entrypoint
│       ├── cli.py                   # Device registration & initial persona seeding CLI
│       ├── core/                    # Config, security, Cloudflare & Bearer auth middleware
│       ├── db/                      # AsyncSession, base models, pgvector helpers
│       ├── models/                  # SQLModel / SQLAlchemy table definitions
│       ├── schemas/                 # Pydantic v2 request/response DTOs
│       ├── api/v1/                  # Routes: /capture, /media, /sync, /search, /sparks, /persona, /reminders, /reading-sessions, /triage, /export
│       ├── services/
│       │   ├── embedder.py          # Singleton google/embeddinggemma-2 wrapper + Redis GPU mutex
│       │   ├── scraper.py           # yt-dlp + PyMuPDF + trafilatura + OCR + faster-whisper
│       │   ├── luna_agent.py        # OpenAI gpt-6-luna client (sparks, voice distillation, Ask Memoria RAG)
│       │   ├── exporter.py          # Obsidian / YAML frontmatter + [[wiki-link]] Markdown exporter
│       │   └── notifier.py          # Self-hosted ntfy HTTP publisher
│       └── workers/
│           └── tasks.py             # Taskiq/ARQ background jobs & cron schedules
├── app_client/                      # Flutter Mobile & Desktop Application
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── core/                    # Network client (Dio + CF Access headers), QR pairing, constants
│       ├── data/
│       │   ├── local/               # Drift database, tables, DAOs
│       │   └── sync/                # Outbox flusher, conflict resolver, ntfy listener
│       └── features/
│           ├── onboarding/          # 1-Scan QR code device pairing UI
│           ├── scratchpad/          # Fast capture, sticky book session banner & append-only annotations
│           ├── sparks/              # Linked AI Spark documents, backlinks & Markdown vault export
│           ├── search/              # Multimodal semantic search + "Ask Memoria" conversational synthesis
│           ├── triage/              # Morning/Evening swipe & hotkey review deck
│           └── share_receiver/      # OS Share Sheet handler
├── extension/                       # WXT Manifest V3 Browser Extension
│   ├── package.json
│   ├── wxt.config.ts
│   └── entrypoints/
│       ├── background.ts            # Context menu, hotkeys, outbox sync, cookie sync & partial-scrape rescue worker
│       ├── content.ts               # Selection / article DOM extractor
│       └── popup/                   # Quick scratchpad capture UI + Rescue Queue badge
└── infra/
    ├── docker-compose.yml
    ├── backup/                      # Automated nightly pg_dump + media manifest backup scripts
    ├── ntfy/server.yml
    └── .env.example
```

---

## 4. Non-Negotiable Architectural & AI Invariants (CRITICAL)

### Invariant 1: Immutable User Captures (`user_raw` vs. `ai_spark` & Append-Only `capture_annotations`)
- **NEVER mutate, overwrite, or rewrite a user's original scratchpad note (`captures.raw_text`).**
- Every user-created note, clipped URL, or uploaded image is stored with `source_type = 'user_raw'` and is strictly read-only to AI workers.
- When a user adds follow-up thoughts or marginalia to an existing capture later, they are stored as **append-only rows** in `capture_annotations` (preserving the original `raw_text` timestamp and wording intact).
- When `gpt-6-luna` generates summaries, connections, or new ideas, it MUST create a separate record in the `ai_sparks` table linked to the parent capture(s) via the `document_links` join table.

### Invariant 2: `google/embeddinggemma-2` Execution Rules
- **Precision Enforcement:** NEVER load or run `google/embeddinggemma-2` in `float16`. Its activation range exceeds `float16` dynamic range and silently produces `NaN` or corrupted vectors. Always enforce:
  ```python
  dtype = torch.bfloat16 if torch.cuda.is_bf16_supported() else torch.float32
  ```
- **Vector Dimension:** Standardize all database vector columns, HNSW indexes, and runtime calls on the full **`768` dimensions** (`VECTOR(768)` in `pgvector`) with L2 normalization (`normalize_embeddings=True`).
  - *Exception:* Only truncate to `256d` (`truncate_dim=256, normalize_embeddings=True`) if explicitly exporting a lightweight vector cache for offline mobile storage. Never use `128d` for multimodal data.
- **Asymmetric Task Prefixes:**
  - Search queries MUST use `prompt_name="SearchQuery"` (`task: search result | query: {query}`).
  - Text documents MUST be formatted as `title: {title or 'none'} | text: {content}`.
  - Raw media tokens (`<|image|>`, `<|video|>`, `<|audio|>`) do NOT take text prefixes when encoded standalone, or must use the exact interleaved dictionary format supported by `SentenceTransformer("google/embeddinggemma-2")`.

### Invariant 3: `gpt-6-luna` Prompt Caching & Privacy Boundary
- Model identifier in OpenAI API calls MUST be `gpt-6-luna`.
- **Prompt Cache Optimization:** Always structure prompts so the static System Instructions + Current `persona.json` Snapshot + Core Scratchpad Index sit at the **exact beginning (prefix)** of the messages array, and variable capture payloads sit at the very end. This maximizes OpenAI's 90% cached input-token discount.
- **Media Privacy Boundary:** Never upload raw user images, personal photos, or video files to the OpenAI cloud API. Extract OCR text and audio transcripts locally on the home server first, and send only scrubbed text representations to `gpt-6-luna`.

### Invariant 4: Instant Capture & Offline-First Outbox (`202 Accepted`)
- No client capture action may ever block on AI processing, media downloading, or network availability.
- Clients write captures to local storage (`Drift` SQLite on Flutter, `storage.local` on WXT) with status `PENDING_SYNC`.
- The server `/api/v1/capture` endpoint MUST validate headers, persist the raw payload to PostgreSQL, enqueue a background job ID in Redis, and return `HTTP 202 Accepted` in **under 50ms**.

### Invariant 5: Zero-Trust Edge Authentication
- Every request from the Flutter app or Browser Extension traversing the Cloudflare Tunnel MUST include:
  1. `CF-Access-Client-Id: <token_id>`
  2. `CF-Access-Client-Secret: <token_secret>`
  3. `Authorization: Bearer <device_scoped_api_key>`
- Never store secrets in git. Load via environment variables on the server and `flutter_secure_storage` / extension local options on clients.

### Invariant 6: Direct `ntfy` Consumption (No Third-Party App Required)
- Do not require the user to install the third-party `ntfy` mobile/desktop app.
- The Flutter client connects directly to the self-hosted `ntfy` endpoint (authenticated via Bearer token) over WebSocket/SSE while active and via periodic background sync worker (`WorkManager`) on Android, rendering alerts natively via `flutter_local_notifications` with deep-link payloads (`scratchpad://spark/<uuid>`).

---

## 5. Coding Agent Workflow & Verification Rules
1. **Contract-First Development:** Before modifying API routes or database tables, check `02_DATABASE_AND_VECTOR_SCHEMA.md` and `03_api_and_sync_contract.md` (and keep `contracts/openapi.json` and `contracts/persona.schema.json` synchronized). Keep Pydantic schemas, Drift tables, and TypeScript interfaces strictly synchronized.
2. **Idempotency:** Every sync endpoint and background worker job MUST be idempotent using client-generated `UUIDv7` (time-ordered UUID) primary keys (`client_capture_id`). Retrying a failed outbox flush must never create duplicate notes.
3. **Strict Typing & Linting:**
   - **Python:** Run `uv run ruff check .` and `uv run mypy app` before completing any backend task.
   - **Flutter:** Run `dart analyze` and `dart run build_runner build --delete-conflicting-outputs` when modifying Drift or Riverpod files.
   - **Extension:** Run `pnpm tsc --noEmit` inside `/extension`.
