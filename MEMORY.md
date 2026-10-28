# Memoria v3 — Project Memory & Context Index

> **Primary Memory Bank Directory:** [`memory-bank/`](./memory-bank/)
> - [`projectbrief.md`](./memory-bank/projectbrief.md) — Foundation identity, philosophy, and core requirements.
> - [`productContext.md`](./memory-bank/productContext.md) — User problems, workflows, and screen-by-screen UX.
> - [`systemPatterns.md`](./memory-bank/systemPatterns.md) — Trust zones, invariants, state machines, and data flows.
> - [`techContext.md`](./memory-bank/techContext.md) — Locked technology stack, hardware constraints, and dev commands.
> - [`activeContext.md`](./memory-bank/activeContext.md) — Current state, immediate focus, active blockers, and decisions.
> - [`progress.md`](./memory-bank/progress.md) — Master 10-task implementation tracker and verification gates.

---

## 1. System Identity
**Memoria v3** is a private, self-hosted personal context, scratchpad, and multimodal ingestion engine. It replaces traditional note-taking with instant, zero-friction capture (thoughts, URLs, articles, technical PDFs, video reels, timestamped YouTube clips, voice memos, and book page scans) backed by a home server multimodal pipeline (`EmbeddingGemma 2`, 768d) and privacy-bounded cloud synthesis (`gpt-6-luna`).

---

## 2. Six Non-Negotiable Invariants
1. **Immutable User Captures (`user_raw` vs. `ai_spark`):** Never modify `captures.raw_text`. User marginalia goes into append-only `capture_annotations`. AI syntheses live in `ai_sparks` linked via `document_links`.
2. **`google/embeddinggemma-2` Execution:** NEVER use `float16` (`bfloat16` on supported GPU, `float32` on CPU). Standardize on `768d` normalized vectors (`VECTOR(768)`). Asymmetric task prefixes for search (`SearchQuery`) and documents; no text task prefix on raw media.
3. **`gpt-6-luna` Prompt Caching & Privacy:** Message[0] system prompt + `persona.json` prefix must be $\ge 1,024$ tokens static to unlock 90% cache discount ($0.01/1M tokens). Zero raw media files sent to cloud LLM.
4. **Sub-50ms Fast Capture SLA:** Client writes locally to offline outbox; server `/api/v1/capture` enqueues background job and returns `HTTP 202 Accepted` in `<50ms`.
5. **Zero-Trust Edge Security:** Requests traversing Cloudflare Tunnel must supply `CF-Access-Client-Id`, `CF-Access-Client-Secret`, and `Authorization: Bearer <device_api_key>`.
6. **Direct `ntfy` Consumption:** Client consumes push alerts natively via WebSocket/SSE and `flutter_local_notifications`; no third-party ntfy client app needed.

---

## 3. Technology Stack Reference
| Component | Technology | Role |
|---|---|---|
| **Backend Framework** | Python 3.12 (`uv`), FastAPI, Pydantic v2 | Async REST API & delta sync endpoints |
| **Database & ORM** | PostgreSQL 16 + `pgvector`, SQLAlchemy 2.0 Async, SQLModel, Alembic | Relational, full-text (BM25), and 768d HNSW vector storage |
| **Worker Queue** | Taskiq + Redis 7 (`io_scrape_queue`, `gpu_ml_queue`, `cloud_llm_queue`) | Media scraping, OCR, embedding, and LLM jobs |
| **Embeddings** | `google/embeddinggemma-2` (740M multimodal) | Unified 768d multimodal embeddings (text, image, audio, video) |
| **Local ML Tools** | `PaddleOCR`, `faster-whisper` (int8), `yt-dlp`, `PyMuPDF`, `trafilatura` | Text extraction, speech-to-text, and video processing on home server |
| **Cloud Synthesis** | OpenAI API (`gpt-6-luna`) | Auto-tagging, voice distillation, idea sparks, Ask Memoria RAG, persona reflection |
| **Client App** | Flutter 3.x (Dart), Riverpod, Drift (SQLite) | Android, Linux GTK, and Windows client with offline outbox |
| **Browser Clipper** | WXT (MV3, TypeScript, Preact, Tailwind CSS) | Browser extension with offline queue, cookie sync, and rescue queue |
| **Push Broker** | Self-hosted `ntfy` container | Real-time alerts with anti-fatigue triage (max 3/day budget) |
| **Tunnel & Gateway** | Cloudflare Tunnel (`cloudflared`) + Cloudflare Access | Zero-Trust edge ingress to home server |

---

## 4. Current Execution State
- **Completed Tasks:**
  - Task 01 (`tasks/01_INFRA_POSTGRES_REDIS_AND_ENV.md`) — `[x] PASSED`
  - Task 02 (`tasks/02_BACKEND_SCAFFOLD_ORM_AND_ALEMBIC.md`) — `[x] PASSED`
- **Next Task:** Task 03 (`tasks/03_AUTH_CLI_QR_PAIRING_AND_FAST_CAPTURE_API.md`) — Zero-Trust auth middleware, `app/cli.py` (`--qr`), `<50ms` `/capture`, `/media` Range stream & `/sync/delta`.

