# System Patterns: Memoria v3

## 1. Network Topology & Trust Zones

```text
+-----------------------------------------------------------------------------------+
| ZONE 1: CLIENT EDGE (Untrusted Networks / Offline-First)                          |
|  - Flutter App (Android, Linux GTK, Windows) via Drift SQLite                     |
|  - WXT Browser Extension (Manifest V3) via browser.storage.local / IndexedDB      |
|  - Outbox Sync Queue using client-generated UUIDv7 primary keys                   |
+-----------------------------------------------------------------------------------+
                                         | HTTPS / WSS
                                         | Headers:
                                         |   CF-Access-Client-Id: <token_id>
                                         |   CF-Access-Client-Secret: <token_secret>
                                         |   Authorization: Bearer <device_key>
                                         |   X-Client-Device-Id: <uuid>
                                         v
+-----------------------------------------------------------------------------------+
| ZONE 2: CLOUDFLARE ZERO TRUST EDGE                                                |
|  - Verifies Service Token before forwarding packet to home network               |
|  - Encrypted outbound tunnel via cloudflared container                            |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| ZONE 3: HOME SERVER — LOCAL PRIVACY ZONE (Docker Compose Bridge Network)         |
|  *RAW MEDIA FILES (IMAGES, AUDIO, REELS, BOOK SCANS) NEVER LEAVE THIS ZONE*       |
|                                                                                   |
|  +------------------------+      Enqueue Job       +---------------------------+  |
|  | FastAPI Server (:8000) | ---------------------> | Redis 7 Broker (:6379)    |  |
|  | - /api/v1/capture (202)|                        | - Taskiq Queue System     |  |
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
|  | ntfy Broker (:80)      | <-----------------------------+             |         |
|  | - Direct WS/SSE stream |                                             |         |
|  +------------------------+                                             |         |
+-------------------------------------------------------------------------|---------+
                                                                          |
                                       Scrubbed Text Snippets Only        |
                                       + Cached persona.json Prefix       |
                                       v                                  v
+-----------------------------------------------------------------------------------+
| ZONE 4: CLOUD SYNTHESIS WORKER (gpt-6-luna)                                       |
|  - Strict prompt cache prefix (>= 1,024 tokens static system block: $0.01/1M)     |
|  - High-signal AI Sparks, Voice Distillation, Ask Memoria RAG, Nightly Persona    |
+-----------------------------------------------------------------------------------+
```

## 2. Invariants & System Architectural Patterns

### Invariant 1: Immutable Captures & Append-Only Marginalia
- `captures.raw_text` and `source_url` are strictly immutable once written.
- User additions / marginalia append new rows to `capture_annotations` referencing `capture_id`.
- AI-synthesized insights are inserted into `ai_sparks` and connected via `document_links`.

### Invariant 2: `google/embeddinggemma-2` Execution Invariants
- **NEVER use `float16`:** Activation range exceeds `float16` dynamic range; produces silent NaNs. Enforce `torch.bfloat16` or `torch.float32`.
- **Dimension Standard:** Full 768 dimensions (`VECTOR(768)`) with `normalize_embeddings=True` and HNSW cosine distance index.
- **Asymmetric Prefixes:** Search queries use `prompt_name="SearchQuery"` (`task: search result | query: {query}`); documents use `title: {title or 'none'} | text: {content}`; raw media tokens (`<|image|>`, `<|video|>`, `<|audio|>`) take NO text task prefix.
- **Concurrency Mutex:** Single GPU/inference instance at a time managed via Redis distributed lock `lock:gpu_inference`.

### Invariant 3: `gpt-6-luna` Prompt Caching Invariant
- Static System Instructions + Current `persona.json` Snapshot + Active Projects / Sparks index structured as `Message[0]` ($\ge 1,024$ tokens) at the beginning of the messages array.
- Variable capture payload structured as `Message[1]` user message.
- Unlocks 90% input discount ($0.01 / 1M cached tokens).
- Privacy boundary: Zero raw media sent to OpenAI cloud API.

### Invariant 4: Fast Ingestion SLA (`<50ms` HTTP 202)
- Fast capture endpoint verifies auth, writes raw record to Postgres, publishes job to Redis, and responds with `HTTP 202 Accepted` within 50ms.
- All heavy extraction, OCR, transcription, embedding, and spark synthesis are handled asynchronously by workers.

### Invariant 5: Zero-Trust Triple-Header Auth
- All requests must supply:
  1. `CF-Access-Client-Id`
  2. `CF-Access-Client-Secret`
  3. `Authorization: Bearer <device_api_key>`
  4. `X-Client-Device-Id`

### Invariant 6: Direct Push Consumption
- Native Flutter WebSocket/SSE client + `flutter_local_notifications` + Android `WorkManager` background sync. No 3rd-party ntfy mobile app required.

## 3. Asynchronous Pipeline State Machine
```
[Client Capture] 
       │ (UUIDv7, PENDING_SYNC)
       ▼
[POST /api/v1/capture] ──(202 Accepted, <50ms)──> Status: QUEUED
       │
       ▼
[Taskiq io_scrape_queue]
   ├── article_url -> trafilatura / dom_fallback_markdown
   ├── video_reel -> yt-dlp + cookie-jar (+ timestamp range clip if ?t=)
   │                  └── ffmpeg audio demux -> audio_16k.wav
   ├── audio_memo -> normalize audio
   └── pdf_document -> PyMuPDF
       │
       ├── (Fail/Login Wall) -> Status: EXTRACTION_PARTIAL (Rescue Queue)
       └── (Success) -> Status: EXTRACTING_MEDIA
       │
       ▼
[Taskiq gpu_ml_queue (lock:gpu_inference)]
   ├── Local OCR: PaddleOCR on images / book pages
   ├── Local Transcription: faster-whisper (int8) on audio
   └── EmbeddingGemma 2: bfloat16/float32, 768d, normalize=True
       │
       ▼
   Status: INDEXED (Stored in pgvector)
       │
       ▼
[Taskiq cloud_llm_queue]
   └── gpt-6-luna Evaluation:
         ├── Auto-tags (1 to 5)
         ├── Voice distillation (if audio_memo)
         ├── High-signal novelty check (>= 0.72) -> ai_sparks + document_links
         └── Anti-fatigue reminder schedule (TIME_SCHEDULED / CONTEXTUAL_MATCH)
       │
       ▼
   Status: SPARK_EVALUATED
```

## 4. Browser Extension Partial-Scrape Rescue Queue
When server-side scraping encounters bot protection or login walls:
1. Server marks `captures.processing_status = 'EXTRACTION_PARTIAL'`.
2. Extension badge shows count of pending rescue items.
3. Extension background worker fetches `/api/v1/media/rescue/queue`.
4. Extension accesses active tab or background context, extracts rendered DOM / authenticated cookies, and submits to `POST /api/v1/media/rescue`.
5. Server resumes worker pipeline to `EMBEDDING` and `INDEXED`.

