# 04_INGESTION_AND_MEDIA_PIPELINE.md
> **ASYNCHRONOUS WORKER QUEUE, MEDIA SCRAPING, OCR & AUDIO EXTRACTION**
> This document specifies the background ingestion pipeline (`app/workers/tasks.py` and `app/services/scraper.py`) powered by **Taskiq + Redis 7**. Every capture must be processed asynchronously without blocking the API or leaking raw media outside the Home Server.

---

## 1. Worker Queue Architecture (`Taskiq` + `Redis 7`)

### 1.1 Queue Partitioning & Concurrency Limits
To prevent CPU/GPU starvation and CUDA Out-Of-Memory (`OOM`) errors across containers on the home server, the worker pool separates I/O-bound scraping from GPU-bound ML inference using distinct Taskiq queues and a **cross-container Redis distributed mutex (`lock:gpu_inference`)**:

| Queue / Lock Name | Concurrency | Responsibility | Timeout |
|---|---|---|---|
| `io_scrape_queue` | `4` async tasks | `trafilatura` HTML extraction, `yt-dlp` video/audio download, `ffmpeg` audio normalization | `120s` |
| `gpu_ml_queue` | `1` (Redis mutex `lock:gpu_inference`) | `PaddleOCR`, `faster-whisper` transcription, and `google/embeddinggemma-2` vector encoding (shared lock with `server-api` search queries) | `180s` |
| `cloud_llm_queue` | `2` async tasks | `gpt-6-luna` spark evaluation, auto-tagging, and nightly persona cron | `60s` |

---

## 2. Modality-Specific Extraction Pipelines (`app/services/scraper.py`)

When `job_ingest_capture(capture_id: UUID)` starts, it sets `captures.processing_status = 'EXTRACTING_MEDIA'` and branches by `capture_type`:

### 2.1 `article_url` (Web Articles, Blogs, HackerNews, Documentation)
1. **Primary Extractor (`trafilatura`):**
   - Fetch URL with custom user-agent and 15-second timeout.
   - Run `trafilatura.extract(downloaded, output_format="markdown", include_links=True, include_images=False, with_metadata=True)`.
2. **Fallback (`dom_fallback_markdown`):**
   - If the capture originated from the WXT Browser Extension, the extension sends the already-rendered DOM selection/article in `dom_fallback_markdown`. Prefer this if `trafilatura` receives `HTTP 403/401`.
3. **Persistence:**
   - Save extracted title to `captures.extracted_title` and clean Markdown to `captures.extracted_markdown`.

---

### 2.2 `video_reel` (Instagram Reels, YouTube Shorts, TikTok, X Videos & Long-Form Timestamped YouTube)
1. **Cookie-Assisted Download & Duration Branching (`yt-dlp` Python API):**
   - If `/data/media/.cookies/cookies.txt` exists (synced from the WXT Browser Extension), pass `"cookiefile": "/data/media/.cookies/cookies.txt"` to `yt-dlp` to bypass Instagram/X/YouTube login walls.
   - **Short-Form Video (`duration <= 600s` / 10 min):**
     ```python
     ydl_opts = {
         "format": "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]/best",
         "outtmpl": f"/data/media/{year}/{month}/{capture_id}/video.%(ext)s",
         "max_filesize": 80 * 1024 * 1024,  # 80 MB hard cap
         "noplaylist": True,
         "quiet": True,
         "writeinfojson": True,
         "writethumbnail": True,
     }
     ```
   - **Long-Form Video (`duration > 600s`) & `?t=` Timestamp Clipping:**
     - Never reject long YouTube talks/podcasts! Instead:
       1. Fetch the subtitle/auto-caption track first (`writesubtitles=True, writeautomaticsub=True, skip_download=True`) and parse into `captures.transcript_text` (0 MB video download).
       2. If `source_url` contains a timestamp parameter (`?t=142s` or `&t=14m20s`), use `yt_dlp.utils.download_range_func(None, [( max(0, t - 30), t + 30 )])` to download **only the 60-second video/audio window** around the shared timestamp so `EmbeddingGemma 2` visually and acoustically embeds the exact moment the user shared.
2. **Audio Track Demuxing (`ffmpeg`):**
   - Extract 16kHz mono WAV for speech transcription and audio embedding:
     ```bash
     ffmpeg -y -i video.mp4 -vn -acodec pcm_s16le -ar 16000 -ac 1 audio_16k.wav
     ```
3. **Local Audio Transcription (`faster-whisper`):**
   - Run `WhisperModel("small.en" or "base", device="cuda/cpu", compute_type="int8")` on `audio_16k.wav` (when subtitles were not already extracted).
   - Store timestamped transcript in `captures.transcript_text`.
4. **Keyframe Visual OCR (Optional for Text-Heavy Coding/Diagram Reels):**
   - Sample 1 frame every 3 seconds; if frame text density is detected, run `PaddleOCR` to capture on-screen code/captions into `captures.ocr_text`.
5. **Graceful Degradation (`EXTRACTION_PARTIAL` + Browser Rescue Queue):**
   - If Instagram/YouTube still blocks `yt-dlp`, catch `DownloadError`, extract OpenGraph title/description via HTTP headers, set `processing_status = 'EXTRACTION_PARTIAL'`, and continue to `EmbeddingGemma 2` using the user's `raw_text` + OpenGraph metadata. The capture will automatically appear in the WXT Browser Extension's **1-Click Rescue Queue**.

---

### 2.3 `book_scan`, `pdf_document` & `image_upload` (Multi-Page Book Sessions, Technical PDFs, Whiteboards)
1. **Active Reading Session Inheritance (`book_scan`):**
   - If `captures.reading_session_id` is set (or an active `reading_sessions` row exists), automatically prepend `"{source_title} ({author}) - {page_range}"` to `extracted_title` and merge `default_tags` into `user_tags`.
2. **Multi-Page Image Preprocessing & PDF Rendering (`Pillow` / `PyMuPDF`):**
   - For `book_scan` (ordered by `media_assets.page_order ASC`): auto-orient via EXIF tags and keep RGB images at `/data/media/.../page_{page_order}.jpg`.
   - For `pdf_document` (ArXiv papers, PDF manuals): open via `PyMuPDF` (`fitz.open()`), extract native text per page into `captures.extracted_markdown`, and render pages containing figures/tables/equations at `150 DPI` as `pdf_page` images (`soft_token_budget = 1120`).
3. **Verbatim Local OCR (`PaddleOCR` with `Tesseract` Fallback):**
   - Run `PaddleOCR(use_angle_cls=True, lang='en')` on each `book_page` / `image_upload` to extract all readable paragraphs, headings, and code blocks in reading order into `captures.ocr_text`.
4. **Soft Token Budget Assignment:**
   - For `book_scan` and `pdf_document` pages (or images with >150 OCR words), set `media_assets.soft_token_budget = 1120` (max visual resolution in `EmbeddingGemma 2`).
   - For standard photos/diagrams (`image_upload`), set `media_assets.soft_token_budget = 280` (or `560`).

---

### 2.4 `audio_memo` (Voice Notes + Thought & Action Distillation)
1. Convert incoming `.m4a` / `.opus` / `.wav` to `16kHz` mono WAV via `ffmpeg`.
2. Transcribe locally with `faster-whisper` -> save verbatim transcript to `captures.transcript_text`.
3. Pass both the raw audio file (`<|audio|>`) and transcript to `EmbeddingGemma 2`.
4. During the subsequent `gpt-6-luna` evaluation step, generate a clean bulleted distillation + action-item extraction into `captures.extraction_metadata["voice_distillation"]` so the user can scan a 2-minute rambling voice note in 3 seconds while preserving the verbatim transcript.

---

## 3. Retry Policy & Dead-Letter Handling

```python
MAX_RETRIES = 3
BACKOFF_SECONDS = [10, 60, 300]  # 10s, 1m, 5m
```
- **Transient Errors (Network timeout, GPU busy):** Increment retry counter in Redis, set `processing_status = 'FAILED_RETRYABLE'`, and reschedule.
- **Permanent Errors ( after 3 retries):** Even if media extraction fails, ALWAYS run a fallback text-only embedding on `coalesce(title, '') + ' ' + coalesce(raw_text, '') + ' ' + coalesce(source_url, '')` so the note is still indexed in `pgvector`, and log the stack trace in `captures.extraction_metadata["error_log"]`.