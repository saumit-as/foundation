# Technical Context: Memoria v3

## 1. Locked Technology Stack & Tooling

### 1.1 Backend & AI Pipeline (`/server`)
- **Runtime:** Python `>=3.12`. Strictly managed via **`uv`** (`pyproject.toml` + `uv.lock`). Never use raw `pip` or `poetry`.
- **API Framework:** **FastAPI** (async-only endpoints, Pydantic v2 strict schemas).
- **Database & ORM:** **PostgreSQL 16** with **`pgvector`** extension (`VECTOR(768)`). ORM: **SQLAlchemy 2.0 (Async)** + **SQLModel** + **Alembic** migrations.
- **Async Workers & Message Broker:** **Taskiq** + **Redis 7** (with queues `io_scrape_queue`, `gpu_ml_queue`, `cloud_llm_queue` and Redis mutex `lock:gpu_inference`).
- **Multimodal Embeddings:** **`google/embeddinggemma-2`** (740M multimodal parameters) loaded via `sentence-transformers` / `transformers` + `torch` in `torch.bfloat16` or `torch.float32`.
- **Extraction Tools:**
  - `yt-dlp` (videos/reels, cookie sync, timestamp range downloads)
  - `trafilatura` (article readability)
  - `PyMuPDF` (`fitz` for technical PDFs)
  - `PaddleOCR` / `pytesseract` (local book scans & image OCR)
  - `faster-whisper` (audio transcription, int8 quantization)
  - `ffmpeg` (audio demuxing & normalization)
- **Cloud Synthesis LLM:** OpenAI API using model **`gpt-6-luna`** (`$0.10/1M` input, `$0.50/1M` output, `90%` cached discount).
- **Push Broker:** Self-hosted **`ntfy`** container (`binwiederhier/ntfy`).

### 1.2 Edge Client (`/app_client`)
- **Framework:** **Flutter** (Dart 3.x) targeting **Android**, **Linux Desktop (GTK)**, and **Windows Desktop**.
- **State Management:** **Riverpod** (`flutter_riverpod` + `riverpod_annotation` + code generation).
- **Local Reactive Database:** **Drift** (reactive SQLite wrapper) with `LocalCaptures`, `LocalCaptureAnnotations`, `LocalMediaAssets`, `LocalAiSparks`, `LocalReadingSessions`, `OutboxSyncQueue`.
- **Networking:** `dio` with custom interceptor attaching CF Access headers & device Bearer token.
- **Hardware Integrations:**
  - `receive_sharing_intent` (Android OS share sheet receiver)
  - `cunning_document_scanner` (camera burst document scanning with edge detection)
  - `mobile_scanner` (1-scan QR code onboarding)
  - `flutter_local_notifications` + Android `workmanager` (periodic sync & native alerts)
  - `uuid` (UUIDv7 time-ordered generation)

### 1.3 Browser Clipper Extension (`/extension`)
- **Framework:** **WXT** (Next-gen Web Extension framework, Manifest V3, TypeScript) managed via **`pnpm`**.
- **UI:** **Preact** + **Tailwind CSS**.
- **Extraction:** `@mozilla/readability` for clean DOM extraction.
- **Local Outbox:** `browser.storage.local` queue with background sync flusher.
- **Rescue Service Worker:** Listens for `EXTRACTION_PARTIAL` queue, syncs cookies (`chrome.cookies`), and sends rendered DOM back to server.

### 1.4 Infrastructure (`/infra`)
- **Container Orchestration:** **Docker Compose**
  - `postgres` (`pgvector/pgvector:pg16`)
  - `redis` (`redis:7-alpine`)
  - `ntfy` (`binwiederhier/ntfy:latest`)
  - `server-api` (FastAPI web server)
  - `server-worker` (Taskiq async worker)
  - `cloudflared` (Cloudflare Tunnel connector)
- **Zero-Trust Access:** Cloudflare Tunnel + Service Token (`CF-Access-Client-Id` / `CF-Access-Client-Secret`).

## 2. Host Machine & Runtime Environment Context
- **Host OS:** Debian GNU/Linux 12 (Bookworm) running Proxmox VE 8.4.21 (`6.8.12-43-pve`).
- **Host Hardware:** Lenovo 81YK with `Intel(R) Core(TM) i7-1065G7 CPU @ 1.30GHz`.
- **Host GPU:** Intel Corporation Iris Plus Graphics G7 (Integrated).
  - *Implication for Embedding & Whisper:* Machine does not have an NVIDIA CUDA GPU (`nvidia-smi` unavailable).
  - `EMBEDDING_DEVICE` must be configured as `cpu` (`torch.float32`), or configured in an environment/container where CPU inference is used.
- **Container Engine Status:** Docker daemon is not yet started/installed on the bare Proxmox outer layer.

## 3. Strict Development & Verification Commands
- **Python Backend:**
  - Linting: `uv run ruff check .`
  - Typing: `uv run mypy app`
  - Migrations: `uv run alembic upgrade head`
  - Tests: `uv run pytest tests/ -v`
- **Flutter App:**
  - Code generation: `dart run build_runner build --delete-conflicting-outputs`
  - Analysis: `flutter analyze`
  - Tests: `flutter test`
- **Browser Extension:**
  - TypeScript check: `pnpm tsc --noEmit`
  - Build: `pnpm wxt build`

