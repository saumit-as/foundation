# 06_LUNA6_SPARK_ENGINE_ASK_MEMORIA_AND_TRIAGE.md
> **TASK 06: `gpt-6-luna` SPARK ENGINE, VOICE DISTILLATION, "ASK MEMORIA" RAG, MARGINALIA, TRIAGE & VAULT EXPORT**
> - **Prerequisites:** Task 05 `[x] PASSED`
> - **Reference Spec:** [`docs/06_luna_6_persona_and_spark_engine.md`](../docs/06_luna_6_persona_and_spark_engine.md) and [`docs/03_api_and_sync_contract.md`](../docs/03_api_and_sync_contract.md)

---

## 1. Objective
Implement `LunaAgentService` (`server/app/services/luna_agent.py`) enforcing the `gpt-6-luna` prompt-caching prefix layout ($\ge 1,024$ tokens at `Message[0]`), strict text-only sanitization, non-destructive `ai_sparks` creation, `audio_memo` thought+action distillation, "Ask Memoria" conversational RAG (`POST /api/v1/search/ask`), intentional spark synthesis (`POST /api/v1/sparks/synthesize`), append-only marginalia (`POST /api/v1/captures/{id}/annotations`), reading sessions (`/api/v1/reading-sessions`), daily triage deck (`/api/v1/triage/*`), Markdown/Obsidian exporter (`server/app/services/exporter.py`), and the nightly `03:00 AM` Persona + `03:30 AM` Vault/Backup cron jobs.

---

## 2. Exact Files to Create / Update

1. `server/pyproject.toml` *(add `openai>=1.54.0`, `pyyaml>=6.0.2`)*
2. `server/app/services/luna_agent.py`
3. `server/app/services/exporter.py`
4. `server/app/api/v1/sparks.py`
5. `server/app/api/v1/persona.py`
6. `server/app/api/v1/reading_sessions.py`
7. `server/app/api/v1/triage.py`
8. `server/app/api/v1/export.py`
9. `server/app/api/v1/capture.py` *(add `POST /api/v1/captures/{id}/annotations` and `PATCH /api/v1/captures/{id}/meta`)*
10. `server/app/api/v1/search.py` *(add `POST /api/v1/search/ask`)*
11. `server/app/workers/tasks.py` *(wire `job_evaluate_spark_and_reminders`, `job_nightly_persona_reflection`, and `job_nightly_backup_and_export`)*
12. `server/app/main.py` *(register all routers)*
13. `server/tests/test_task_06_luna_workflows.py`

---

## 3. Step-by-Step Implementation Instructions

### Step 3.1: Implement `LunaAgentService` (`server/app/services/luna_agent.py`)
1. **Strict Privacy Sanitizer (`_build_scrubbed_capture_payload`):**
   - Strip all binary paths (`local_rel_path`), raw media bytes, and internal DB fields. Include only `id`, `capture_type`, `captured_at`, `title`, `raw_text`, `annotations_concat`, `extracted_markdown`, `ocr_text`, and `transcript_text`.
2. **Deterministic Cached Prompt Prefix (`Message[0]`):**
   - Load `PersonaSnapshot.cached_prompt_prefix` (`is_current = True`). Verify `len(cached_prompt_prefix) >= 4096` chars ($\ge 1,024$ tokens) so OpenAI's 90% prompt cache hits on every call.
   - Always place `{"role": "system", "content": cached_prompt_prefix}` as `messages[0]` and the dynamic payload as `messages[1]`.
3. **Structured Output Methods (`model="gpt-6-luna"`):**
   - `evaluate_capture(capture, top_k_related) -> LunaCaptureEvaluation` (returns `auto_tags`, `voice_distillation` when `capture_type == 'audio_memo'`, `should_create_spark`, `novelty_score`, `spark_document`, `reminder`).
   - `ask_memoria(question: str, retrieved_items: list[dict]) -> LunaAskResponse` (returns grounded `answer_markdown` with `[item_id]` citations, `cited_items`, `follow_up_questions`).
   - `synthesize_explicit_spark(captures: list[Capture], user_angle: str | None) -> SparkDocumentDraft`.
   - `reflect_persona_nightly(current_persona: dict, recent_captures: list, recent_sparks: list, triage_signals: dict) -> tuple[dict, str]` (validates output against `contracts/persona.schema.json`).

### Step 3.2: Implement Append-Only Annotations, Reading Sessions, Triage & Exporter
- **Append-Only Annotations (`POST /api/v1/captures/{id}/annotations`):**
  - Inserts into `capture_annotations` (`ON CONFLICT (id) DO NOTHING`), appends `\n[Annotation]: {content}` to `captures.annotations_concat` **without touching `captures.raw_text`**, and re-encodes `chunk_index = 0` in `embeddings`.
- **Daily Triage Deck (`GET /api/v1/triage/deck` & `POST /api/v1/triage/{item_id}/decision`):**
  - `KEEP`: sets `is_triage_reviewed = True`.
  - `PIN_TO_PROJECT`: sets `is_triage_reviewed = True`, adds `project_slug` to `user_tags` (or `is_pinned = True` on `ai_sparks`).
  - `ARCHIVE`: sets `is_triage_reviewed = True, is_archived = True`.
  - `DISMISS`: sets `is_dismissed = True` on `ai_sparks` (or `is_archived = True` on `captures`).
- **Markdown / Obsidian Vault Exporter (`server/app/services/exporter.py` & `/api/v1/export`):**
  - Renders YAML frontmatter (`id`, `title`, `type`, `created_at`, `tags`, `related_project`, `source_links: ["[[uuid|title]]"]`), body Markdown, and a `## Source Captures (Immutable)` section quoting the parent `captures.raw_text`.

---

## 4. Deterministic Verification Gate (`PASS / FAIL`)

Write `server/tests/test_task_06_luna_workflows.py` verifying:
1. **Prompt Prefix Byte-Stability:** Calling `_build_messages()` across 3 different captures produces 100% byte-identical `messages[0]["content"]` with length $\ge 4,096$ chars.
2. **Non-Destructive Spark & Audio Distillation:** Running `job_evaluate_spark_and_reminders` on an `audio_memo` capture populates `auto_tags` and `extraction_metadata["voice_distillation"]`, creates a new row in `ai_sparks` + `document_links`, and leaves `captures.raw_text` and `captures.transcript_text` 100% unchanged.
3. **Append-Only Marginalia:** Calling `POST /api/v1/captures/{id}/annotations` creates a `capture_annotations` row, updates `captures.annotations_concat` and `search_tsv`, and leaves `captures.raw_text` untouched.
4. **"Ask Memoria" & Intentional Synthesis:** `POST /api/v1/search/ask` and `POST /api/v1/sparks/synthesize` return valid cited Markdown and persist a new `ai_spark` when `save_as_spark=True`.
5. **Triage & Obsidian Export:** `POST /api/v1/triage/{id}/decision` updates triage state, and `GET /api/v1/sparks/{id}/export.md` outputs valid YAML frontmatter and `[[wiki-links]]`.

Run:
```powershell
cd server
uv run ruff check .
uv run mypy app
uv run pytest tests/test_task_06_luna_workflows.py -v
```
- **Success Criteria:** `0` lint/type errors and `5 passed` in pytest (exit code `0`). Mark **Task 06** as `[x] PASSED` in `tasks/00_TASK_RUNNER_AND_INDEX.md`.
