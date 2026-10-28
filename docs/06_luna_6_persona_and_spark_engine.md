# 06_LUNA6_PERSONA_AND_SPARK_ENGINE.md
> **CLOUD SYNTHESIS, PROMPT CACHING & QUIET PERSONA ENGINE (`gpt-6-luna`)**
> This document specifies `app/services/luna_agent.py`. It defines how the home server interacts with OpenAI's **`gpt-6-luna`** model (`$0.10/1M` input, `$0.50/1M` output, `90%` cached input discount) to quietly maintain the user's persona and generate non-destructive **Linked Idea Spark Documents** (`ai_spark`).

---

## 1. Privacy & Non-Destructive Synthesis Rules

1. **Strict Text-Only Sanitization:** Never transmit raw images, video files, audio files, or local filesystem paths to OpenAI. Only send `raw_text`, `extracted_markdown`, `ocr_text`, `transcript_text`, and `chunk_preview_text`.
2. **Never Rewrite `user_raw` Captures:** `gpt-6-luna` has zero write permissions to `captures.raw_text` or `captures.title`. All synthesized thoughts MUST be saved as new records in `ai_sparks` linked to parent `captures` via `document_links`.
3. **High-Signal Spark Threshold:** Do not create an `ai_spark` for every mundane note. Only generate a spark when:
   - A new capture bridges $\ge 2$ previously unconnected notes/reels, **OR**
   - A capture directly answers an open question in `persona_json.current_learning_threads`, **OR**
   - A capture provides actionable architectural/project insight for an item in `persona_json.active_projects`.

---

## 2. Deterministic Prompt-Caching Layout (`90%` Input Discount)

OpenAI automatically caches prompt prefixes $\ge 1,024$ tokens when the leading bytes of the `messages` array are 100% identical across requests.

To guarantee cache hits across every capture evaluation throughout the day, `luna_agent.py` MUST structure the `messages` array into a **Static Cached Prefix (`Message[0]`)** and a **Dynamic Suffix (`Message[1]`)**:

### 2.1 `Message[0]` (`role: "system"` — Identical All Day, Cached at `$0.01 / 1M` tokens)
Stored pre-rendered in `persona_snapshots.cached_prompt_prefix` and refreshed only once per 24 hours by the nightly persona cron job:

```text
You are the background synthesis and context engine for a private Personal Knowledge & Scratchpad System.
Your job is to evaluate a newly ingested user capture against retrieved historical notes and the user's evolving Persona Profile.

### NON-NEGOTIABLE OPERATING RULES
1. NEVER rewrite or suggest replacing the user's original note.
2. Quietly assign 1 to 5 lowercase semantic `auto_tags`.
3. Evaluate whether this capture sparks a genuine, high-signal synthesis (`should_create_spark: true`) with the retrieved historical items or active persona projects. Avoid trivial summaries.
4. When `should_create_spark` is true, author a standalone Markdown document (`spark_document`) that cites the connected notes and expands the idea, architecture, or insight.
5. Evaluate if the user needs a follow-up reminder (`reminder_suggestion`)—either `TIME_SCHEDULED` (if the note mentions an upcoming task/look-into item) or `CONTEXTUAL_MATCH` (if an unread saved link strongly matches today's thought).

### CURRENT USER PERSONA SNAPSHOT (STATIC CACHE BLOCK)
{{RENDERED_PERSONA_JSON_SNAPSHOT}}

### ACTIVE PROJECT & LEARNING THREAD INDEX (STATIC CACHE BLOCK)
{{RENDERED_ACTIVE_PROJECTS_AND_RECENT_SPARK_TITLES_PADDED_OVER_1024_TOKENS}}
```

### 2.2 `Message[1]` (`role: "user"` — Dynamic Per Capture)
```json
{
  "new_capture": {
    "id": "0192d04e-7b2a-7000-814f-9f0c8d1a2b3c",
    "capture_type": "video_reel",
    "captured_at": "2026-10-28T03:15:00Z",
    "title": "Zero Trust DNS Architecture Reel",
    "user_raw_text": "Check how he configures unbound with cloudflared #homelab #dns",
    "extracted_content": "Transcript: In this setup we bind Unbound to port 5335... OCR: unbound.conf interface 127.0.0.1@5335"
  },
  "top_k_related_history": [
    {
      "id": "0192c110-1122-7000-9abc-001122334455",
      "table": "captures",
      "similarity": 0.84,
      "title": "Cloudflare Tunnel latency notes",
      "snippet": "Need to avoid hairpin NAT when resolving internal services on mobile..."
    }
  ]
}
```

---

## 3. Structured Output Schema (`response_format`)

All calls to `gpt-6-luna` MUST use OpenAI Structured Outputs (`response_format={"type": "json_schema", ...}`) matching this Pydantic v2 model:

```python
from pydantic import BaseModel, Field
from typing import Literal


class SparkDocumentDraft(BaseModel):
    title: str = Field(description="Concise, insightful title for the new AI Spark document")
    spark_markdown: str = Field(
        description="Full Markdown synthesis expanding the idea, preserving original context via references"
    )
    spark_rationale: str = Field(
        description="1-sentence explanation of why these captures were connected"
    )
    related_project_slug: str | None = Field(
        description="Slug from persona_json.active_projects if applicable"
    )
    connected_item_ids: list[str] = Field(
        description="UUIDs of parent captures or sparks synthesized in this document"
    )


class ReminderDraft(BaseModel):
    should_remind: bool
    reminder_type: Literal["TIME_SCHEDULED", "CONTEXTUAL_MATCH", "SPACED_REVIEW"] | None
    title: str | None
    message: str | None
    delay_hours: int | None = Field(
        description="Hours from now to fire the reminder (e.g., 4, 24, 72)"
    )


class VoiceDistillationDraft(BaseModel):
    summary_bullets: list[str] = Field(
        description="2 to 4 concise bullet points distilling a rambling audio_memo without altering verbatim transcript_text"
    )
    action_items: list[str] = Field(
        default_factory=list,
        description="Explicit tasks or follow-ups spoken in the voice memo",
    )


class LunaCaptureEvaluation(BaseModel):
    auto_tags: list[str] = Field(max_length=5)
    voice_distillation: VoiceDistillationDraft | None = Field(
        default=None,
        description="Populated when capture_type == 'audio_memo' to give an instant scannable summary above the verbatim transcript",
    )
    should_create_spark: bool
    novelty_score: float = Field(ge=0.0, le=1.0)
    spark_document: SparkDocumentDraft | None
    reminder: ReminderDraft


class CitedSourceItem(BaseModel):
    item_id: str
    item_table: Literal["captures", "ai_sparks"]
    relevance_note: str


class LunaAskResponse(BaseModel):
    """Structured response for POST /api/v1/search/ask ('Ask Memoria' On-Demand RAG)."""

    answer_markdown: str = Field(
        description="Grounded Markdown synthesis answering the user's question with inline [item_id] citations"
    )
    cited_items: list[CitedSourceItem]
    follow_up_questions: list[str] = Field(max_length=3)
```

---

## 4. Nightly Quiet Persona Reflection Cron (`03:00 AM`) & Triage Feedback Loop

Executed once daily by Taskiq cron (`job_nightly_persona_reflection`):
1. Fetch all `captures` and `ai_sparks` created or triaged in the past 24 hours, plus the current `persona_snapshots` row (`is_current = TRUE`).
2. Include explicit user signals from the **Daily Triage Deck** (`POST /api/v1/triage/{id}/decision`):
   - **Positive Signals (`PIN_TO_PROJECT`, `is_pinned = TRUE`, appended `capture_annotations`):** Boost `priority_weight` on the corresponding project/topic.
   - **Negative Signals (`DISMISS`, `is_dismissed = TRUE`, rapid `ARCHIVE` without reading):** Lower topic weight or move noisy topics toward `ignored_or_archived_topics` and raise `spark_threshold` if too many low-signal sparks were dismissed.
3. Call `gpt-6-luna` with instructions to:
   - Adjust `priority_weight` on `active_projects` based on recent capture activity and triage feedback.
   - Add newly emerging topics or open questions to `current_learning_threads`.
   - Decay or move stale topics (>30 days without activity) to `ignored_or_archived_topics`.
4. Validate the returned JSON against `contracts/persona.schema.json`.
5. Render the new `cached_prompt_prefix` (ensuring $\ge 1,024$ tokens by including the top 25 active project/spark summaries), mark old snapshots `is_current = FALSE`, and insert the new `persona_snapshots` version.