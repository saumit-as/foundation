# 05_MULTIMODAL_SCRAPER_OCR_WHISPER_AND_WORKERS.md
> **TASK 05: TASKIQ WORKER QUEUES, MULTIMODAL SCRAPING (`yt-dlp`, `PyMuPDF`, `PaddleOCR`, `faster-whisper`), COOKIE SYNC & BROWSER RESCUE**
> - **Prerequisites:** Task 04 `[x] PASSED`
> - **Reference Spec:** [`docs/04_ingestion_and_media_pipeline.md`](../docs/04_ingestion_and_media_pipeline.md) and [`docs/03_api_and_sync_contract.md`](../docs/03_api_and_sync_contract.md)

---

## 1. Objective
Implement the asynchronous multimodal extraction service (`server/app/services/scraper.py`), the Taskiq background worker pipeline (`server/app/workers/tasks.py`) with retry/dead-letter fallback, and the WXT Browser Extension helper endpoints (`/api/v1/scraper/cookies`, `/api/v1/captures/partial`, `/api/v1/captures/{id}/rescue`).

---

## 2. Exact Files to Create / Update

1. `server/pyproject.toml` *(add `trafilatura>=1.12.2`, `yt-dlp>=2024.10.22`, `pymupdf>=1.24.13`, `faster-whisper>=1.0.3`, `pytesseract>=0.3.13` / `paddleocr`)*
2. `server/app/services/scraper.py`
3. `server/app/workers/__init__.py`
4. `server/app/workers/tasks.py`
5. `server/app/api/v1/scraper.py`
6. `server/app/main.py` *(register `/api/v1/scraper` and `/api/v1/captures/partial` & `/rescue` routes)*
7. `server/tests/test_task_05_scraper_workers.py`

---

## 3. Step-by-Step Implementation Instructions

### Step 3.1: Implement Multimodal Extractor (`server/app/services/scraper.py`)
Implement clean, testable methods for every `CaptureTypeEnum` modality matching `docs/04_ingestion_and_media_pipeline.md` Section 2:
1. **`extract_article(url: str, dom_fallback_markdown: str | None)`:**
   - Runs `trafilatura.fetch_url` + `trafilatura.extract(..., output_format="markdown", with_metadata=True)`.
   - If HTTP `401/403` or empty result and `dom_fallback_markdown` is provided, uses `dom_fallback_markdown`.
2. **`extract_pdf(pdf_path: Path, capture_id: UUID)`:**
   - Opens with `fitz.open(pdf_path)` (`PyMuPDF`), extracts full text per page into Markdown, and renders pages containing images/drawings or dense layout at `150 DPI` (`page.get_pixmap(dpi=150)`) into `{MEDIA_ROOT}/{YYYY}/{MM}/{capture_id}/pdf_page_{i}.jpg` with `soft_token_budget = 1120`.
3. **`extract_video_reel(url: str, capture_id: UUID)`:**
   - Checks if `/data/media/.cookies/cookies.txt` exists and adds `"cookiefile"` to `ydl_opts`.
   - Extracts metadata first (`extract_info(url, download=False)`).
   - **Short video (`duration <= 600s`):** Downloads MP4 (`<=720p`, max 80MB), extracts 16kHz mono WAV via `ffmpeg`, and runs `faster-whisper` (`transcribe_audio`).
   - **Long video (`duration > 600s`):** Extracts subtitle/auto-caption track into `transcript_text` without downloading the full video; if `url` has `?t=` or `&t=` timestamp, parses timestamp `t_sec` and uses `download_range_func(None, [(max(0, t_sec - 30), t_sec + 30)])` to download only the 60-second video clip around `t_sec`.
   - **Blocked / Login Wall Fallback:** On `yt_dlp.utils.DownloadError`, fetches OpenGraph `<meta property="og:title">` / `og:description`, and raises a typed `PartialExtractionError(og_title, og_description)` so the worker sets `processing_status = ProcessingStatusEnum.EXTRACTION_PARTIAL`.
4. **`extract_image_or_book_ocr(image_paths: list[Path], is_book_scan: bool)`:**
   - Auto-orients each image via `Pillow.ImageOps.exif_transpose`.
   - Runs `PaddleOCR` (with `pytesseract` fallback if PaddleOCR binary is unavailable on host) in reading order (`page_order ASC`) and assigns `soft_token_budget = 1120` for `book_scan` (or >150 OCR words) else `280`.
5. **`transcribe_audio(audio_path: Path)`:**
   - Normalizes audio to 16kHz mono WAV with `ffmpeg` and transcribes with `faster-whisper` (acquiring the Redis `lock:gpu_inference` mutex).

### Step 3.2: Implement Taskiq Worker & Fallback Pipeline (`server/app/workers/tasks.py`)
Implement `job_ingest_capture(capture_id: UUID)`:
1. Transition `capture.processing_status = ProcessingStatusEnum.EXTRACTING_MEDIA`.
2. If `capture.reading_session_id` is set, fetch `ReadingSession` and prepend `f"{session.source_title} ({session.author or ''}) - {capture.page_range or ''}".strip()` to `extracted_title` and merge `session.default_tags` into `capture.user_tags`.
3. Run the modality-specific extractor from `scraper.py`.
   - If `PartialExtractionError` is caught, set `processing_status = ProcessingStatusEnum.EXTRACTION_PARTIAL` and still proceed to embed the user's `raw_text` + OpenGraph metadata so the capture is immediately searchable!
4. Transition to `EMBEDDING` (unless `EXTRACTION_PARTIAL`, which preserves `EXTRACTION_PARTIAL` status while still writing its fallback `Embedding` row), encode via `EmbeddingGemmaService`, and upsert into `embeddings`.
5. Transition to `INDEXED` (or keep `EXTRACTION_PARTIAL` if partial) and enqueue `job_evaluate_spark_and_reminders(capture_id)`.
6. Implement the 3-retry exponential backoff (`[10, 60, 300]`) and permanent error fallback from `docs/04_ingestion_and_media_pipeline.md` Section 3 (always indexing at least `title + raw_text + source_url` even if media extraction fails after 3 retries).

### Step 3.3: Implement Cookie Sync & Browser Rescue Endpoints (`server/app/api/v1/scraper.py`)
- `POST /api/v1/scraper/cookies`: Saves Netscape cookie text to `{settings.MEDIA_ROOT}/.cookies/cookies.txt` (`0o600` permissions).
- `GET /api/v1/captures/partial`: Returns all captures where `processing_status == 'EXTRACTION_PARTIAL'` and `not is_deleted`.
- `POST /api/v1/captures/{id}/rescue`: Updates `extracted_title` and `extracted_markdown = dom_fallback_markdown`, resets `processing_status = 'QUEUED'`, re-runs `job_ingest_capture(id)`, and returns `202 Accepted`.

---

## 4. Deterministic Verification Gate (`PASS / FAIL`)

Write `server/tests/test_task_05_scraper_workers.py` verifying:
1. Ingesting a `pdf_document` capture (using a generated 2-page test PDF via `fitz.open()`) extracts native text, renders page images with `soft_token_budget = 1120`, and transitions the capture to `INDEXED` with rows in `embeddings`.
2. Ingesting a `book_scan` linked to an active `ReadingSession` inherits `source_title` and `default_tags`.
3. Simulating a blocked Instagram Reel (`DownloadError`) transitions the capture to `EXTRACTION_PARTIAL` while still writing a fallback `embeddings` vector so it is searchable.
4. Calling `GET /api/v1/captures/partial` lists the blocked capture, and calling `POST /api/v1/captures/{id}/rescue` with `dom_fallback_markdown` upgrades the capture to `INDEXED`.
5. Timestamp parser for long YouTube URLs (`https://www.youtube.com/watch?v=abc12345&t=142s`) computes the exact `[112, 172]` (`±30s`) clip range.

Run:
```powershell
cd server
uv run ruff check .
uv run mypy app
uv run pytest tests/test_task_05_scraper_workers.py -v
```
- **Success Criteria:** `0` lint/type errors and `5 passed` in pytest (exit code `0`). Mark **Task 05** as `[x] PASSED` in `tasks/00_TASK_RUNNER_AND_INDEX.md`.
