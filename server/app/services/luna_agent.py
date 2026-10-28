from __future__ import annotations

import json
import logging
from typing import Any, Literal

from openai import AsyncOpenAI
from pydantic import BaseModel, Field

from app.core.config import settings
from app.models.enums import CaptureTypeEnum
from app.models.tables import Capture

logger = logging.getLogger(__name__)


# Pydantic Schemas for Structured Outputs
class SparkDocumentDraft(BaseModel):
    title: str = Field(description="Concise, insightful title for the new AI Spark document")
    spark_markdown: str = Field(
        description="Full Markdown synthesis expanding the idea, preserving original context via references"
    )
    spark_rationale: str = Field(
        description="1-sentence explanation of why these captures were connected"
    )
    related_project_slug: str | None = Field(
        default=None, description="Slug from persona_json.active_projects if applicable"
    )
    connected_item_ids: list[str] = Field(
        description="UUIDs of parent captures or sparks synthesized in this document"
    )


class ReminderDraft(BaseModel):
    should_remind: bool = False
    reminder_type: Literal["TIME_SCHEDULED", "CONTEXTUAL_MATCH", "SPACED_REVIEW"] | None = None
    title: str | None = None
    message: str | None = None
    delay_hours: int | None = Field(
        default=None, description="Hours from now to fire the reminder (e.g. 4, 24, 72)"
    )


class VoiceDistillationDraft(BaseModel):
    summary_bullets: list[str] = Field(
        description="2 to 4 concise bullet points distilling an audio_memo without altering verbatim transcript_text"
    )
    action_items: list[str] = Field(
        default_factory=list,
        description="Explicit tasks or follow-ups spoken in the voice memo",
    )


class LunaCaptureEvaluation(BaseModel):
    auto_tags: list[str] = Field(default_factory=list, max_length=5)
    voice_distillation: VoiceDistillationDraft | None = Field(
        default=None,
        description="Populated when capture_type == 'audio_memo' to give an instant scannable summary",
    )
    should_create_spark: bool = False
    novelty_score: float = Field(default=0.0, ge=0.0, le=1.0)
    spark_document: SparkDocumentDraft | None = None
    reminder: ReminderDraft = Field(default_factory=ReminderDraft)


class CitedSourceItem(BaseModel):
    item_id: str
    item_table: Literal["captures", "ai_sparks"]
    relevance_note: str


class LunaAskResponse(BaseModel):
    """Structured response for 'Ask Memoria' conversational RAG."""

    answer_markdown: str = Field(
        description="Grounded Markdown synthesis answering user's question with inline [item_id] citations"
    )
    cited_items: list[CitedSourceItem] = Field(default_factory=list)
    follow_up_questions: list[str] = Field(default_factory=list, max_length=3)


_openai_client_override: AsyncOpenAI | None = None


def get_openai_client() -> AsyncOpenAI:
    global _openai_client_override
    if _openai_client_override is not None:
        return _openai_client_override
    return AsyncOpenAI(api_key=settings.OPENAI_API_KEY)


def set_openai_client(client: AsyncOpenAI | None) -> None:
    global _openai_client_override
    _openai_client_override = client


class LunaAgentService:
    def __init__(self, model: str = "gpt-6-luna") -> None:
        self.model = model

    def _build_scrubbed_capture_payload(
        self,
        capture: Capture,
        top_k_related: list[dict[str, Any]],
    ) -> dict[str, Any]:
        """Privacy Barrier: strips all local file paths, raw media bytes, and internal DB flags."""
        extracted_content = (
            capture.extracted_markdown
            or capture.ocr_text
            or capture.transcript_text
            or ""
        )
        return {
            "new_capture": {
                "id": str(capture.id),
                "capture_type": str(capture.capture_type.value if hasattr(capture.capture_type, "value") else capture.capture_type),
                "captured_at": capture.captured_at.isoformat() if capture.captured_at else None,
                "title": capture.title or capture.extracted_title,
                "user_raw_text": capture.raw_text,
                "user_annotations": capture.annotations_concat,
                "extracted_content": extracted_content[:8000],  # Scrubbed text snippet
            },
            "top_k_related_history": [
                {
                    "id": str(item.get("item_id")),
                    "table": str(item.get("item_table")),
                    "similarity": round(float(item.get("semantic_similarity", 0.0)), 3),
                    "title": str(item.get("title") or "Untitled"),
                    "snippet": str(item.get("snippet") or "")[:500],
                }
                for item in top_k_related
            ],
        }

    def _build_messages(
        self,
        cached_prompt_prefix: str,
        dynamic_payload: dict[str, Any],
    ) -> list[dict[str, str]]:
        """Structures messages array into Static Cached Prefix (Message[0]) and Dynamic Suffix (Message[1])."""
        # Ensure cached prompt prefix is byte-stable and >= 4096 characters (>= 1024 tokens)
        if len(cached_prompt_prefix) < 4096:
            # Pad deterministically so OpenAI prompt caching kicks in
            padding = " " + ("### CACHE_ALIGNMENT_PADDING_BLOCK\n" * 150)
            cached_prompt_prefix = cached_prompt_prefix + padding

        return [
            {"role": "system", "content": cached_prompt_prefix},
            {"role": "user", "content": json.dumps(dynamic_payload, sort_keys=True)},
        ]

    async def evaluate_capture(
        self,
        capture: Capture,
        top_k_related: list[dict[str, Any]],
        cached_prompt_prefix: str,
    ) -> LunaCaptureEvaluation:
        """Evaluates a newly ingested capture against history and persona."""
        client = get_openai_client()
        dynamic_payload = self._build_scrubbed_capture_payload(capture, top_k_related)
        messages = self._build_messages(cached_prompt_prefix, dynamic_payload)

        try:
            response = await client.beta.chat.completions.parse(
                model=self.model,
                messages=messages,  # type: ignore[arg-type]
                response_format=LunaCaptureEvaluation,
            )
            parsed = response.choices[0].message.parsed
            if parsed:
                return parsed
        except Exception as exc:
            logger.warning("OpenAI parse failed (%s), attempting raw completion parsing", exc)

        # Fallback heuristic if API unavailable
        is_audio = capture.capture_type == CaptureTypeEnum.audio_memo
        distillation = None
        if is_audio and capture.transcript_text:
            distillation = VoiceDistillationDraft(
                summary_bullets=[
                    f"Voice memo recorded: {capture.transcript_text[:100]}..."
                ],
                action_items=[],
            )

        return LunaCaptureEvaluation(
            auto_tags=["scratchpad", "note"],
            voice_distillation=distillation,
            should_create_spark=False,
            novelty_score=0.5,
            spark_document=None,
            reminder=ReminderDraft(should_remind=False),
        )

    async def ask_memoria(
        self,
        question: str,
        retrieved_items: list[dict[str, Any]],
        cached_prompt_prefix: str,
    ) -> LunaAskResponse:
        """Conversational RAG grounded strictly on the user's scratchpad items."""
        client = get_openai_client()
        dynamic_payload = {
            "task": "ask_memoria_rag",
            "question": question,
            "context_items": [
                {
                    "item_id": str(i.get("item_id")),
                    "table": str(i.get("item_table")),
                    "title": str(i.get("title") or "Untitled"),
                    "snippet": str(i.get("snippet") or "")[:800],
                }
                for i in retrieved_items
            ],
        }
        messages = self._build_messages(cached_prompt_prefix, dynamic_payload)

        try:
            response = await client.beta.chat.completions.parse(
                model=self.model,
                messages=messages,  # type: ignore[arg-type]
                response_format=LunaAskResponse,
            )
            parsed = response.choices[0].message.parsed
            if parsed:
                return parsed
        except Exception as exc:
            logger.warning("OpenAI ask_memoria parse failed: %s", exc)

        # Fallback response
        cited = [
            CitedSourceItem(
                item_id=str(i.get("item_id")),
                item_table="captures" if i.get("item_table") == "captures" else "ai_sparks",
                relevance_note="Retrieved via hybrid search",
            )
            for i in retrieved_items[:3]
        ]
        snippets = "\n".join([f"- [{i.get('item_id')}]: {i.get('snippet', '')[:120]}" for i in retrieved_items[:3]])
        return LunaAskResponse(
            answer_markdown=f"Based on your notes:\n\n{snippets}\n\nRegarding '{question}', your recorded context connects to these items.",
            cited_items=cited,
            follow_up_questions=["Would you like to synthesize these into a spark?"],
        )

    async def synthesize_explicit_spark(
        self,
        captures: list[Capture],
        user_angle: str | None,
        cached_prompt_prefix: str,
    ) -> SparkDocumentDraft:
        """On-demand user request to synthesize 2 or more captures into an AI Spark."""
        client = get_openai_client()
        dynamic_payload = {
            "task": "explicit_synthesis",
            "user_angle": user_angle,
            "captures": [
                {
                    "id": str(c.id),
                    "title": c.title or c.extracted_title,
                    "content": (c.extracted_markdown or c.ocr_text or c.raw_text or "")[:1500],
                }
                for c in captures
            ],
        }
        messages = self._build_messages(cached_prompt_prefix, dynamic_payload)

        try:
            response = await client.beta.chat.completions.parse(
                model=self.model,
                messages=messages,  # type: ignore[arg-type]
                response_format=SparkDocumentDraft,
            )
            parsed = response.choices[0].message.parsed
            if parsed:
                return parsed
        except Exception as exc:
            logger.warning("OpenAI spark synthesis parse failed: %s", exc)

        titles = ", ".join([c.title or "Note" for c in captures])
        return SparkDocumentDraft(
            title=f"Synthesis: {titles[:50]}",
            spark_markdown=f"# Synthesis of Connected Notes\n\nSynthesizing context across {len(captures)} notes.\n\n"
            + "\n".join([f"- [{c.id}]: {c.raw_text or ''}" for c in captures]),
            spark_rationale=user_angle or "User requested synthesis of selected captures.",
            related_project_slug=None,
            connected_item_ids=[str(c.id) for c in captures],
        )
