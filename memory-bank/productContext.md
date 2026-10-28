# Product Context: Memoria v3

## 1. Problem Statement
Knowledge workers, engineers, and researchers consume and produce fragmented information across dozens of touchpoints every day:
- Fleeting thoughts typed on mobile while walking.
- Instagram Reels or TikTok videos demonstrating homelab, coding, or electronics setups.
- Deep-dive technical blog posts and documentation clipped from the desktop browser.
- Multi-page excerpts and diagrams photographed from physical technical books.
- Long-form YouTube lectures where only a 60-second segment is relevant.
- Rambling voice memos recorded while commuting.

Existing note tools force users to prematurely file, tag, and categorize these inputs, leading to high friction, abandoned notes, and lost context. Furthermore, uploading personal media and voice memos to public cloud LLMs creates unacceptable privacy leakage.

## 2. Product Solution & User Experience
Memoria v3 delivers a zero-friction, privacy-preserving personal context engine:

### 2.1 Frictionless Edge Capture
- **Immediate Zero-Tap Entry:** The Flutter app opens with keyboard focus in the capture input. Writing a thought and hitting submit stores it to local Drift SQLite in `<15ms` and queues it for outbox sync.
- **Android OS Share Sheet:** Share Reels, YouTube links, PDFs, web URLs, or images directly from any mobile app. A lightweight overlay allows an optional 1-line thought or `#tag` before saving instantly.
- **WXT Browser Extension:** One-click clipper in Chrome/Firefox/Brave that captures article text, selections, and automatically extracts DOM context (`dom_fallback_markdown`). Includes cookie sync to rescue walled content on the server.

### 2.2 Active Reading & Book Scanning Sessions
- **Sticky Banner:** Users tap to activate a book (e.g., *"📖 Active Book: Crafting Interpreters"*).
- **Burst Scanner:** Tapping the camera button launches continuous multi-page scanning with automatic edge detection and perspective correction (`cunning_document_scanner`), indexing pages sequentially (`page_order = 0, 1, 2...`) linked to the active reading session.

### 2.3 Voice Memo Distillation
- Voice notes recorded on the go are locally transcribed via `faster-whisper`.
- `gpt-6-luna` distills rambling transcripts into 2–4 concise summary bullets and explicit action items, displayed as a **Voice Distillation Card** directly above the audio player while keeping the verbatim transcript collapsible and intact.

### 2.4 AI Sparks & Idea Graph
- The system quietly watches newly ingested notes and links them across time.
- When high-signal connections emerge ($\ge 2$ previously unconnected notes bridged, active project relevance, or answering a learning thread), `gpt-6-luna` drafts an **AI Spark** document.
- Users can view backlinks, see connected source cards, and export sparks to an Obsidian vault (`GET /api/v1/sparks/{id}/export.md`) with YAML frontmatter and `[[wiki-links]]`.

### 2.5 Morning & Evening Triage Deck
- A daily review deck (swipeable on mobile, hotkey-driven `J`/`K`/`P`/`E`/`X`/`Space` on desktop).
- Users pin items to active projects, archive completed ideas, or dismiss irrelevant recommendations.
- Feedback directly adjusts weights and learning threads in the user's `persona.json` during nightly reflection (03:00 AM).

### 2.6 Hybrid Search & "Ask Memoria" RAG
- **Hybrid Search:** Combines multimodal vector similarity (`google/embeddinggemma-2` 768d) with PostgreSQL trigram/BM25 full-text search via Reciprocal Rank Fusion (RRF 60). Results badge the modality (video frame, audio transcript, book page, note).
- **Ask Memoria:** Conversational RAG synthesized by `gpt-6-luna` across retrieved captures with inline citations `[capture_id]` and a 1-tap option to save the answer as a new AI Spark.

