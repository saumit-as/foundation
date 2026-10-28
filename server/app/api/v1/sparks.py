from __future__ import annotations

import logging
import uuid
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Response, status
from pydantic import BaseModel, Field
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col, select

from app.core.security import get_current_device
from app.db.session import get_async_session
from app.models.enums import LinkTypeEnum
from app.models.tables import AISpark, Capture, Device, DocumentLink, Embedding, PersonaSnapshot
from app.services.exporter import export_spark_to_markdown
from app.services.luna_agent import LunaAgentService

logger = logging.getLogger(__name__)

router = APIRouter(tags=["AI Sparks"])


class SparkSynthesisRequest(BaseModel):
    capture_ids: list[uuid.UUID] = Field(..., min_length=2, max_length=15)
    user_angle: str | None = Field(default=None, description="Optional angle or focus requested by user")


class SparkDetailResponse(BaseModel):
    id: uuid.UUID
    title: str
    spark_markdown: str
    spark_rationale: str
    related_project: str | None
    is_pinned: bool
    is_dismissed: bool
    connected_captures: list[dict[str, Any]] = []


@router.get("/sparks", response_model=list[AISpark])
async def list_sparks(
    include_dismissed: bool = False,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> list[AISpark]:
    """Returns all AI Sparks (excluding dismissed by default)."""
    stmt = select(AISpark)
    if not include_dismissed:
        stmt = stmt.where(col(AISpark.is_dismissed).is_(False))
    stmt = stmt.order_by(col(AISpark.created_at).desc())
    res = await session.execute(stmt)
    return list(res.scalars().all())


@router.get("/sparks/{spark_id}", response_model=SparkDetailResponse)
async def get_spark_detail(
    spark_id: uuid.UUID,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> SparkDetailResponse:
    """Returns AI Spark details with connected parent captures."""
    spark = await session.get(AISpark, spark_id)
    if not spark:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Spark not found")

    # Find linked captures
    link_stmt = select(DocumentLink).where(
        col(DocumentLink.source_id) == spark_id,
        col(DocumentLink.target_table) == "captures",
    )
    link_res = await session.execute(link_stmt)
    links = link_res.scalars().all()
    target_ids = [lnk.target_id for lnk in links]

    caps_stmt = select(Capture).where(col(Capture.id).in_(target_ids))
    caps_res = await session.execute(caps_stmt)
    captures = caps_res.scalars().all()

    connected = [
        {
            "id": str(c.id),
            "title": c.title or c.extracted_title,
            "raw_text": c.raw_text,
            "capture_type": str(c.capture_type),
        }
        for c in captures
    ]

    return SparkDetailResponse(
        id=spark.id,
        title=spark.title,
        spark_markdown=spark.spark_markdown,
        spark_rationale=spark.spark_rationale,
        related_project=spark.related_project,
        is_pinned=spark.is_pinned,
        is_dismissed=spark.is_dismissed,
        connected_captures=connected,
    )


@router.post("/sparks/synthesize", response_model=SparkDetailResponse, status_code=status.HTTP_201_CREATED)
async def synthesize_sparks_endpoint(
    payload: SparkSynthesisRequest,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> SparkDetailResponse:
    """User-initiated synthesis of 2+ captures into an AI Spark."""
    caps_stmt = select(Capture).where(col(Capture.id).in_(payload.capture_ids))
    caps_res = await session.execute(caps_stmt)
    captures = list(caps_res.scalars().all())

    if len(captures) < 2:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="At least 2 valid captures required for synthesis")

    # Load persona cached prefix
    p_stmt = (
        select(PersonaSnapshot)
        .where(col(PersonaSnapshot.is_current).is_(True))
        .order_by(col(PersonaSnapshot.version_number).desc())
        .limit(1)
    )
    p_res = await session.execute(p_stmt)
    snapshot = p_res.scalar_one_or_none()
    cached_prefix = snapshot.cached_prompt_prefix if snapshot else "You are Memoria AI Spark engine."

    luna = LunaAgentService()
    draft = await luna.synthesize_explicit_spark(captures, payload.user_angle, cached_prefix)

    spark_id = uuid.uuid4()
    spark = AISpark(
        id=spark_id,
        title=draft.title,
        spark_markdown=draft.spark_markdown,
        spark_rationale=draft.spark_rationale,
        related_project=draft.related_project_slug,
    )
    session.add(spark)

    # Insert document links
    for c in captures:
        link = DocumentLink(
            id=uuid.uuid4(),
            source_id=spark_id,
            source_table="ai_sparks",
            target_id=c.id,
            target_table="captures",
            link_type=LinkTypeEnum.SPARK_SOURCE,
        )
        session.add(link)

    # Embed new spark
    try:
        from app.workers.tasks import get_embedder

        embedder = get_embedder()
        vec = await embedder.encode_text_document(spark.title, spark.spark_markdown)
        emb_stmt = (
            pg_insert(Embedding)
            .values(
                id=uuid.uuid4(),
                owner_id=spark_id,
                owner_table="ai_sparks",
                chunk_index=0,
                modality_composition="text",
                chunk_preview_text=spark.spark_markdown[:1200],
                token_count=len(spark.spark_markdown.split()),
                embedding=vec,
            )
            .on_conflict_do_update(
                index_elements=["owner_id", "owner_table", "chunk_index"],
                set_={
                    "chunk_preview_text": spark.spark_markdown[:1200],
                    "token_count": len(spark.spark_markdown.split()),
                    "embedding": vec,
                },
            )
        )
        await session.execute(emb_stmt)
    except Exception as exc:
        logger.debug("Spark embedding error: %s", exc)

    await session.commit()

    return SparkDetailResponse(
        id=spark.id,
        title=spark.title,
        spark_markdown=spark.spark_markdown,
        spark_rationale=spark.spark_rationale,
        related_project=spark.related_project,
        is_pinned=spark.is_pinned,
        is_dismissed=spark.is_dismissed,
        connected_captures=[{"id": str(c.id), "title": c.title} for c in captures],
    )


@router.get("/sparks/{spark_id}/export.md")
async def export_spark_markdown(
    spark_id: uuid.UUID,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> Response:
    """Exports AI Spark as Obsidian Markdown with YAML frontmatter and [[wiki-links]]."""
    spark = await session.get(AISpark, spark_id)
    if not spark:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Spark not found")

    link_stmt = select(DocumentLink).where(
        col(DocumentLink.source_id) == spark_id,
        col(DocumentLink.target_table) == "captures",
    )
    link_res = await session.execute(link_stmt)
    links = link_res.scalars().all()
    target_ids = [lnk.target_id for lnk in links]

    caps_stmt = select(Capture).where(col(Capture.id).in_(target_ids))
    caps_res = await session.execute(caps_stmt)
    captures = list(caps_res.scalars().all())

    md_content = export_spark_to_markdown(spark, captures)
    return Response(
        content=md_content,
        media_type="text/markdown; charset=utf-8",
        headers={"Content-Disposition": f'attachment; filename="spark_{spark_id}.md"'},
    )
