# Project Brief: Memoria v3

## 1. System Identity
**Memoria v3** is a private, self-hosted personal context, scratchpad, and multimodal ingestion engine. It is designed for fast, frictionless capture across all personal devices, paired with an asynchronous home server pipeline that enriches, indexes, and synthesizes captures without leaking raw media to the cloud.

## 2. Core Philosophy & Value Proposition
- **Not a Generic Note-Taking App:** Instead of manual folder organization or note categorizing, Memoria is a fast-capture scratchpad that ingests unstructured thoughts, clipped URLs, web articles, technical PDFs, short-form video reels (Instagram/TikTok/Shorts), long-form timestamped YouTube clips, audio memos, and multi-page book scan sessions.
- **Privacy & Compute Split:**
  - **Edge Clients (Flutter & WXT Extension):** Local-first capture using offline outbox queues, 1-scan QR code onboarding, active reading sessions, and a daily triage deck.
  - **Home Server (Local Privacy Zone):** Docker Compose environment (`PostgreSQL 16 + pgvector`, `Redis 7`, `FastAPI`, `Taskiq`, `ntfy`, `cloudflared`). Executes local OCR (`PaddleOCR`), local audio transcription (`faster-whisper`), media extraction (`yt-dlp`, `trafilatura`, `PyMuPDF`), and multimodal vector indexing using **`google/embeddinggemma-2`** (768d). **Raw media files never leave the home server.**
  - **Cloud Synthesis Worker (`gpt-6-luna`):** Called strictly with scrubbed text snippets and a cached `persona.json` prefix to update user persona state, distill audio memos into bulleted action items, power conversational "Ask Memoria" RAG, and author non-destructive **Linked Idea Spark Documents** (`ai_spark`).

## 3. High-Level Requirements & Capabilities
1. **Sub-50ms Fast Capture:** Client writes locally to SQLite / IndexedDB outbox; server `/api/v1/capture` validates and enqueues in `<50ms` returning `HTTP 202 Accepted`.
2. **Immutable User Raw Content:** User captures (`source_type = 'user_raw'`) are strictly read-only to AI workers. Follow-up notes/marginalia are append-only rows in `capture_annotations`.
3. **Non-Destructive AI Sparks:** `gpt-6-luna` generates standalone Markdown synthesis documents in `ai_sparks`, poly-linked to parent captures via `document_links`.
4. **Multimodal Vector Indexing:** Unified 768-dimensional embeddings using `google/embeddinggemma-2` (`bfloat16`/`float32` only, no `float16`) stored in `pgvector` with HNSW cosine index.
5. **Prompt-Caching Optimization:** System prompt and `persona.json` state structured as a static prefix $\ge 1,024$ tokens to unlock OpenAI's 90% cached input discount ($0.01/1M tokens).
6. **Zero-Trust Edge Security:** Cloudflare Tunnel protected by Cloudflare Access Service Tokens (`CF-Access-Client-Id`, `CF-Access-Client-Secret`) and device-scoped Bearer API keys.
7. **Direct `ntfy` Consumption:** Self-hosted notification broker with native Flutter/Desktop consumption (no 3rd-party app required).
8. **Active Reading Sessions:** Sticky banner for book scanning burst sessions, grouping pages under reading session records.
9. **Daily Triage Deck:** Morning and evening swipe/hotkey review deck feeding explicit relevance signals back into nightly persona reflection.
10. **Obsidian / Markdown Vault Export:** One-click export of AI Sparks and notes with YAML frontmatter and `[[wiki-links]]`.

