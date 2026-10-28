# 01_ARCHITECTURE_AND_DATA_FLOW.md
> **SYSTEM TOPOLOGY, TRUST BOUNDARIES & STATE MACHINES**
> This document defines the runtime topology, network trust zones, end-to-end data flows, and state machine transitions for the Personal Context, Scratchpad, and Multimodal Ingestion Engine. Coding agents must ensure all service interactions and state transitions strictly adhere to this specification.

---

## 1. Network Trust Zones & Privacy Boundaries

The system is partitioned into four strict trust and compute zones. Data crossing between zones must follow the sanitization and authentication rules below:

```text
+-----------------------------------------------------------------------------------+
| ZONE 1: CLIENT EDGE (Untrusted Networks / Offline-Capable)                        |
|                                                                                   |
|  +-----------------------------------+     +-----------------------------------+  |
|  | Flutter App (Android/Linux/Win)   |     | WXT Browser Extension (MV3)       |  |
|  | - Drift SQLite (Local State)      |     | - Preact Popup + DOM Clipper      |  |
|  | - Outbox Sync Queue (UUIDv7)      |     | - browser.storage.local Outbox    |  |
|  | - Direct ntfy WebSocket/SSE       |     | - Background Service Worker       |  |
|  +-----------------+-----------------+     +-----------------+-----------------+  |
+--------------------|-----------------------------------------|--------------------+
                     | HTTPS / WSS                             | HTTPS
                     | Headers:                                | Headers:
                     | - CF-Access-Client-Id                   | - CF-Access-Client-Id
                     | - CF-Access-Client-Secret               | - CF-Access-Client-Secret
                     | - Authorization: Bearer <device_key>    | - Authorization: Bearer <ext_key>
                     v                                         v
+-----------------------------------------------------------------------------------+
| ZONE 2: CLOUDFLARE ZERO TRUST EDGE                                                |
|  - Validates Service Token before forwarding any packet to home network           |
|  - Routes validated traffic through encrypted `cloudflared` outbound tunnel       |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
| ZONE 3: HOME SERVER — LOCAL PRIVACY ZONE (Docker Compose Network)                 |
|  *RAW MEDIA (IMAGES, REELS, AUDIO, BOOK SCANS) NEVER LEAVE THIS ZONE*             |
|                                                                                   |
|  +------------------------+      Enqueue Job       +---------------------------+  |
|  | FastAPI Server (:8000) | ---------------------> | Redis 7 Broker (:6379)    |  |
|  | - /api/v1/capture (202)|                        | - Taskiq / ARQ Queues     |  |
|  | - /api/v1/sync         |                        +-------------+-------------+  |
|  | - /api/v1/search       |                                      |                |
|  +-----------+------------+                                      v                |
|              |                                     +---------------------------+  |
|              | Read/Write                          | Async Worker Pool         |  |
|              v                                     | 1. Scraper (yt-dlp/trafil)|  |
|  +------------------------+                        | 2. Local OCR (PaddleOCR)  |  |
|  | PostgreSQL 16 (:5432)  | <--------------------> | 3. Audio (faster-whisper) |  |
|  | - pgvector VECTOR(768) |   Write Vectors/Docs   | 4. EmbeddingGemma 2 (GPU) |  |
|  | - Immutable user_raw   |                        +------+-------------+------+  |
|  | - Linked ai_sparks     |                               |             |         |
|  | - persona.json state   |                               |             |         |
|  +------------------------+                               |             |         |
|                                                           |             |         |
|  +------------------------+        Publish Alert          |             |         |
|  | Self-Hosted ntfy (:80) | <-----------------------------+             |         |
|  +------------------------+                                             |         |
+-------------------------------------------------------------------------|---------+
                                                                          |
                                     HTTPS (Outbound Only)                |
                                     *Scrubbed Text + Cached Persona ONLY*|
                                                                          v
+-----------------------------------------------------------------------------------+
| ZONE 4: EXTERNAL CLOUD SYNTHESIS (OpenAI API)                                     |
|  - Model: `gpt-6-luna` ($0.10/1M input, $0.50/1M output, 90% cached input disc.)  |
|  - Receives: Static System Prompt + Persona JSON Prefix + Top-K Text Snippets     |
|  - Returns: Structured JSON for `ai_spark` docs, backlinks, and persona updates   |
+-----------------------------------------------------------------------------------+
```

### Boundary Enforcement Rules
1. **No Inbound Open Ports on Home Router:** `cloudflared` establishes an outbound-only tunnel from Zone 3 to Zone 2.
2. **Double Authentication:** Cloudflare Zero Trust verifies `CF-Access-Client-Id` and `CF-Access-Client-Secret` at the edge. FastAPI middleware independently verifies the `Authorization: Bearer <device_scoped_api_key>` token to identify which device created the capture.
3. **Strict Media Sanitization for Zone 4:** Before calling `gpt-6-luna`, the worker strips binary media blobs and local filesystem paths, passing only extracted plain text (OCR output, Whisper transcript, article markdown, and user notes).

---

## 2. Core Data Flow Pipelines

### Flow A: Instant Capture & Offline Outbox Sync
Designed so user capture latency is **0ms locally** and **<50ms over the network**.

1. **Client Capture:**
   - User types a thought, shares a Reel/article via Android Share Sheet, scans a book page, or clips text via the WXT Browser Extension.
   - Client generates a time-ordered **`UUIDv7`** (`id`) and writes the record into its local storage (`Drift` SQLite `captures` table + `outbox_queue` table on Flutter; `browser.storage.local` on WXT) with `sync_status = 'PENDING_SYNC'`.
2. **Outbox Flush:**
   - If offline, the item sits in `outbox_queue` while remaining immediately visible and editable (append/tag) in the local UI.
   - When network connectivity is available, the Sync Service sends `POST /api/v1/capture` (or `/api/v1/capture/batch` for queued items).
   - If the capture contains a local image, audio memo, or book scan, the client uploads via multipart stream or presigned chunked upload alongside the metadata JSON.
3. **Server Fast-Ack (`202 Accepted`):**
   - FastAPI validates auth headers, performs an idempotent `INSERT ... ON CONFLICT (id) DO NOTHING` into PostgreSQL `captures` with `processing_status = 'QUEUED'`, pushes `job_ingest_capture(capture_id)` to Redis, and immediately returns `HTTP 202 Accepted`.
   - Client marks the outbox entry as `SYNCED` and removes it from `outbox_queue`.

---

### Flow B: Multimodal Ingestion, Extraction & `EmbeddingGemma 2` Indexing
Executed asynchronously inside the Python Worker Pool so heavy media never blocks API requests.

1. **Type-Specific Extraction (`services/scraper.py`):**
   - **Plain Text / Markdown Note:** Normalizes whitespace, extracts inline `#tags` and URLs.
   - **Article URL:** Fetches HTML via `trafilatura` (with headless browser or WXT DOM fallback if needed), extracts clean Markdown text, title, author, and lead image.
   - **Technical PDF (`pdf_document`):** Parses pages via `PyMuPDF` (`fitz`), extracting native text layers and rendering diagram/dense pages at 150 DPI as `<|image|>` assets (`soft_token_budget = 1120`).
   - **Short Video / Reel / YouTube URL:** Executes `yt-dlp` (using optional browser-synced Netscape cookies at `/data/media/.cookies/cookies.txt` to bypass social login walls). For short videos (`<= 10m`), downloads up to 720p video + 16kHz WAV audio and runs `faster-whisper` locally. For long-form YouTube videos (`> 10m`), fetches the subtitle/transcript track directly (0 MB video download) and, if a `?t=` timestamp parameter was shared, clips only the `±30s` (`60s` window) video segment around that timestamp.
   - **Book Page / Multi-Page Burst Scan (`book_scan`):** Associates the scan with the user's active `reading_sessions` book context (auto-inheriting book title, author, and `#book` tags), saves ordered page images (`page_order = 0, 1, ...`) to `/data/media/<capture_id>/`, and runs local OCR (`PaddleOCR` / `Tesseract`) to extract verbatim text for exact keyword search and cloud LLM context.
2. **Unified Multimodal Embedding (`services/embedder.py`):**
   - The worker loads the singleton `google/embeddinggemma-2` model in **`bfloat16`** (or `float32` on CPU).
   - Constructs the modality-appropriate input within the **8,192-token budget**:
     - **Text-only capture:** Formats as `title: {title or 'none'} | text: {content}`.
     - **Image / Book scan + Note:** Interleaves text note + OCR text + `<|image|>` placeholder (scaling `max_soft_tokens` up to `560` or `1120` for dense book pages).
     - **Reel / Video:** Interleaves caption + `<|video|>` (sampled at `1 FPS`, up to 32 frames at `140 tokens/frame`) + `<|audio|>` (`25 tokens/sec`).
   - Encodes into a single L2-normalized **`768d` vector** (`VECTOR(768)`) and writes it to PostgreSQL `embeddings` (indexed via `pgvector` HNSW cosine ops).
   - For long articles or multi-page book scans exceeding 8,192 tokens, chunks the content into overlapping semantic windows and stores child vectors (`chunk_index = 0, 1, 2...`) linked to `owner_id = capture_id` (`owner_table = 'captures'`).
3. **Transition to Spark Evaluation:**
   - Updates `captures.processing_status = 'INDEXED'` and enqueues `job_evaluate_spark_and_reminders(capture_id)`.

---

### Flow C: Non-Destructive Idea Sparking & Quiet Persona Evolution (`gpt-6-luna`)

1. **Top-K Contextual Retrieval:**
   - Using the newly generated `768d` embedding of the capture, the worker queries `pgvector` for the top `K=8` most semantically similar past captures and existing `ai_spark` documents (cosine similarity `> 0.68`).
2. **Cache-Optimized `gpt-6-luna` Invocation (`services/luna_agent.py`):**
   - Constructs the OpenAI `gpt-6-luna` request with a deterministic prefix to guarantee a **90% Prompt Cache hit**:
     - **Message 0 (System - Cached Prefix):** Core agent instructions + JSON output schema + Static Persona Snapshot (`persona.json`) + Active Project Threads list.
     - **Message 1 (User - Variable Suffix):** New capture text/transcript/OCR + Top-8 retrieved historical snippets (with their UUIDs and timestamps).
3. **Non-Destructive Output Processing & Voice Memo Distillation:**
   - `gpt-6-luna` returns a structured JSON decision:
     - `auto_tags`: Array of semantic tags applied to capture metadata (never altering raw user text).
     - `voice_distillation` (for `audio_memo`): Concise bulleted distillation + extracted action items stored in `captures.extraction_metadata["voice_distillation"]` while keeping `transcript_text` 100% verbatim.
     - `should_create_spark`: Boolean (`true` only if the new capture forms a non-obvious synthesis, answers an open question, or extends an active project thread).
     - `spark_document`: Title, Markdown body synthesizing the idea, and `source_capture_ids` (array of parent `user_raw` UUIDs).
     - `reminder_suggestion`: Optional follow-up trigger (`remind_at` timestamp or contextual condition + reason).
   - If `should_create_spark == true`, the worker inserts a new row into `ai_sparks` (`source_type = 'ai_spark'`), records bidirectional edges in `document_links`, embeds the new spark via `EmbeddingGemma 2`, and triggers a push notification via `ntfy`.
4. **Nightly Quiet Persona Cron (`03:00 AM Local Time`):**
   - A scheduled Taskiq cron job gathers all captures, sparks, and explicit user triage feedback (`KEEP`, `PIN_TO_PROJECT`, `ARCHIVE`, `DISMISS`) from the last 24 hours, passes them with the current `persona.json` to `gpt-6-luna`, and writes an updated `persona_snapshots` row (tracking evolving skills, active topics, tone preferences, and decayed interests) while invalidating/refreshing the static prompt cache prefix for the next day.

---

### Flow D: Multimodal Semantic Search & "Ask Memoria" On-Demand Synthesis

1. **Query Encoding:**
   - User enters a search query in the Flutter app (e.g., *"that reel about zero-trust home lab DNS"* or *"book page about memory allocation"*).
   - FastAPI `/api/v1/search` passes the query string to `EmbeddingGemma 2` using the asymmetric query prefix:
     ```python
     query_vec = model.encode(query_text, prompt_name="SearchQuery", normalize_embeddings=True)
     ```
2. **Hybrid Retrieval (`pgvector` + Full-Text Search):**
   - Executes a Reciprocal Rank Fusion (RRF) query combining:
     - **Vector Cosine Similarity (`<=>`)** across `embeddings` (matching text queries directly against video frames, audio tracks, images, `captures`, and `ai_sparks` in the unified `768d` space).
     - **PostgreSQL `tsvector` BM25 Keyword Match** across both `captures.search_tsv` (raw text, append-only annotations, OCR output, Whisper transcripts, extracted Markdown) and `ai_sparks.search_tsv`.
   - Applies a deterministic `1.15x` persona re-ranking boost to items linked to active projects in `persona.json`.
3. **On-Demand Conversational RAG ("Ask Memoria" & Intentional Sparking):**
   - When the user switches search to **Ask Mode** (`POST /api/v1/search/ask`) or selects multiple captures and clicks **"Synthesize into Spark"** (`POST /api/v1/sparks/synthesize`), the server feeds the retrieved scrubbed text snippets to `gpt-6-luna` behind the cached `Message[0]` persona prefix, returning a grounded Markdown synthesis with clickable `[capture_id]` citations and optionally saving it as a permanent `ai_spark`.

---

### Flow E: Push Reminders & Multi-Device State Sync

1. **Notification Dispatch (`services/notifier.py`):**
   - When a reminder timer fires or a high-value `ai_spark` is generated, the worker sends an authenticated `POST` to the internal `ntfy` container (`http://ntfy:80/scratchpad_alerts`) with headers:
     - `Title`, `Priority`, `Tags`, and `Click: scratchpad://item/<uuid>`.
2. **Client Consumption (No Third-Party `ntfy` App):**
   - **Desktop (Linux/Windows) & Foreground Android:** Flutter maintains an authenticated WebSocket (`wss://<tunnel-domain>/ntfy/scratchpad_alerts/ws`) and fires a native OS notification via `flutter_local_notifications`.
   - **Background Android:** `WorkManager` periodic task (or foreground service toggle) polls `/api/v1/sync/delta?since=<last_cursor>` + `ntfy` cached messages `?since=<last_id>&poll=1`, syncing new `ai_sparks` into local Drift SQLite and surfacing local notifications.

---

## 3. Capture Lifecycle State Machine

Every record in `captures` progresses through two orthogonal state machines: **Client Sync State** and **Server Processing State**.

### A. Client Sync State (`sync_status` in Drift SQLite)
```text
[CREATED_LOCALLY] ---> [PENDING_SYNC] ---> [UPLOADING_MEDIA] ---> [SYNCED]
                             |                    |
                             +--------------------+---> [SYNC_RETRY_BACKOFF]
```
- `PENDING_SYNC`: Written to local SQLite; waiting for network/tunnel reachability.
- `UPLOADING_MEDIA`: Multipart binary upload in progress for image/audio/book scan.
- `SYNC_RETRY_BACKOFF`: Exponential backoff (2s, 4s, 8s... max 15m) if tunnel returns `5xx` or network drops.
- `SYNCED`: Server returned `202 Accepted` with matching `client_capture_id`.

### B. Server Processing State (`processing_status` in PostgreSQL)
```text
[QUEUED] ---> [EXTRACTING_MEDIA] ---> [EMBEDDING] ---> [INDEXED] ---> [SPARK_EVALUATED]
                    |                     |
                    v                     v
             [EXTRACTION_PARTIAL]    [FAILED_RETRYABLE] ---> [DEAD_LETTER]
```
- `QUEUED`: Persisted in Postgres; job waiting in Redis.
- `EXTRACTING_MEDIA`: Running `yt-dlp`, `trafilatura`, `PaddleOCR`, or `faster-whisper`.
- `EXTRACTION_PARTIAL`: URL scrape blocked (e.g., login wall on Reel); fallback metadata/caption saved so the link and user note are still embedded and searchable, and flagged for optional browser-extension DOM assist.
- `EMBEDDING`: Running `google/embeddinggemma-2` (`bfloat16` / `768d`).
- `INDEXED`: Vector committed to `pgvector`; item is immediately searchable via RAG.
- `SPARK_EVALUATED`: `gpt-6-luna` has evaluated connections, assigned tags, and created any applicable `ai_spark` and reminder rows.

---

## 4. Failure Modes & Resilience Patterns

1. **Scraper Blocked on Instagram/YouTube Reel (`EXTRACTION_PARTIAL` + Cookie Sync & Browser Rescue):**
   - To minimize blocks upfront, the WXT Browser Extension can optionally push a scoped Netscape cookie jar (`POST /api/v1/scraper/cookies`) to `/data/media/.cookies/cookies.txt` for `yt-dlp`.
   - If `yt-dlp` still hits an IP block or private reel wall on the server, the worker does NOT discard the capture. It embeds the URL + user note + OpenGraph tags immediately, marks `processing_status = 'EXTRACTION_PARTIAL'`, and surfaces the item in the WXT Browser Extension's **"Rescue Queue"** (`GET /api/v1/captures/partial` -> `POST /api/v1/captures/{id}/rescue`) so the desktop browser can supply the rendered DOM/metadata in one click.
2. **VRAM Contention on Home Server:**
   - Both `server-api` (running with `--workers 1`) and `server-worker` coordinate GPU execution via a cross-process Redis distributed mutex lock (`redis.lock.Lock("lock:gpu_inference", timeout=120)`) combined with an in-process `asyncio.Lock()`. This guarantees `faster-whisper`, `PaddleOCR`, and `EmbeddingGemma 2` never execute concurrent CUDA forward passes or duplicate model weights across multiple worker processes.
3. **OpenAI Cloud Outage or Rate Limit:**
   - Because `EmbeddingGemma 2` runs locally in Zone 3, **capture, OCR, transcription, and multimodal semantic search (`INDEXED`) continue working 100% locally** even if OpenAI's API or external internet is down. `gpt-6-luna` spark jobs simply wait in Redis until cloud reachability resumes.
