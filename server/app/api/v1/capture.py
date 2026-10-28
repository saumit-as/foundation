import logging
import uuid
from datetime import UTC, datetime
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from redis.asyncio import from_url as redis_from_url
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col, select

from app.core.config import settings
from app.core.security import get_current_device
from app.db.session import get_async_session
from app.models.enums import CaptureTypeEnum, ProcessingStatusEnum
from app.models.tables import Capture, CaptureAnnotation, Device, Embedding, ReadingSession
from app.schemas.capture import (
    CaptureAcceptedResponse,
    CaptureBatchRequest,
    CaptureBatchResponse,
    CaptureCreateRequest,
)

logger = logging.getLogger(__name__)
router = APIRouter()


async def try_enqueue_capture_job(capture_id_str: str) -> None:
    """Non-blocking Redis job enqueue; gracefully skips if Redis is mocked/unreachable."""
    try:
        r = redis_from_url(settings.REDIS_URL, decode_responses=True)
        await r.lpush("queue:io_scrape_queue", capture_id_str)
        await r.aclose()
    except Exception as exc:
        logger.debug(f"Redis enqueue non-critical notice: {exc}")


@router.post(
    "/capture",
    response_model=CaptureAcceptedResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Single Instant Capture (<50ms SLA)",
)
async def create_capture(
    payload: CaptureCreateRequest,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> CaptureAcceptedResponse:
    reading_session_id = payload.reading_session_id

    # Auto-link active reading session for book scans if not explicitly provided
    if reading_session_id is None and payload.capture_type == CaptureTypeEnum.book_scan:
        stmt = (
            select(ReadingSession)
            .where(col(ReadingSession.is_active).is_(True))
            .order_by(col(ReadingSession.updated_at).desc())
            .limit(1)
        )
        res = await session.execute(stmt)
        active_session = res.scalar_one_or_none()
        if active_session:
            reading_session_id = active_session.id

    insert_stmt = (
        pg_insert(Capture)
        .values(
            id=payload.id,
            device_id=device.id,
            reading_session_id=reading_session_id,
            capture_type=payload.capture_type,
            processing_status=ProcessingStatusEnum.QUEUED,
            title=payload.title,
            raw_text=payload.raw_text,
            source_url=payload.source_url,
            page_range=payload.page_range,
            user_tags=payload.user_tags,
            extracted_markdown=payload.dom_fallback_markdown,
            captured_at=payload.captured_at,
        )
        .on_conflict_do_nothing(index_elements=["id"])
    )

    await session.execute(insert_stmt)
    await session.commit()

    # Query existing/inserted record to retrieve current status and sync_version
    query_stmt = select(Capture).where(col(Capture.id) == payload.id)
    result = await session.execute(query_stmt)
    capture = result.scalar_one()

    # Asynchronously enqueue ingestion pipeline in Redis
    await try_enqueue_capture_job(str(capture.id))

    return CaptureAcceptedResponse(
        status="ACCEPTED",
        id=capture.id,
        processing_status=capture.processing_status,
        sync_version=capture.sync_version,
    )


@router.post(
    "/capture/batch",
    response_model=CaptureBatchResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Offline Outbox Batch Flush (up to 50 items)",
)
async def create_capture_batch(
    payload: CaptureBatchRequest,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> CaptureBatchResponse:
    accepted_ids = []
    max_sync_version = 0

    for item in payload.captures:
        insert_stmt = (
            pg_insert(Capture)
            .values(
                id=item.id,
                device_id=device.id,
                reading_session_id=item.reading_session_id,
                capture_type=item.capture_type,
                processing_status=ProcessingStatusEnum.QUEUED,
                title=item.title,
                raw_text=item.raw_text,
                source_url=item.source_url,
                page_range=item.page_range,
                user_tags=item.user_tags,
                extracted_markdown=item.dom_fallback_markdown,
                captured_at=item.captured_at,
            )
            .on_conflict_do_nothing(index_elements=["id"])
        )
        await session.execute(insert_stmt)

    await session.commit()

    # Retrieve all items to collect IDs and max sync_version
    ids = [item.id for item in payload.captures]
    q = select(Capture).where(col(Capture.id).in_(ids))
    res = await session.execute(q)
    rows = res.scalars().all()

    for r in rows:
        accepted_ids.append(r.id)
        if r.sync_version > max_sync_version:
            max_sync_version = r.sync_version
        await try_enqueue_capture_job(str(r.id))

    return CaptureBatchResponse(
        status="ACCEPTED",
        processed_count=len(accepted_ids),
        accepted_ids=accepted_ids,
        max_sync_version=max_sync_version,
    )


class AnnotationCreateRequest(BaseModel):
    content: str = Field(..., min_length=1)


class CaptureMetaUpdateRequest(BaseModel):
    title: str | None = None
    user_tags: list[str] | None = None
    page_range: str | None = None


@router.post("/captures/{capture_id}/annotations", status_code=status.HTTP_201_CREATED)
async def add_capture_annotation(
    capture_id: UUID,
    payload: AnnotationCreateRequest,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> dict[str, Any]:
    """Append-only marginalia: appends follow-up thoughts without mutating original raw_text."""
    capture = await session.get(Capture, capture_id)
    if not capture or capture.is_deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Capture not found")

    annotation_id = uuid.uuid4()
    annotation = CaptureAnnotation(
        id=annotation_id,
        capture_id=capture_id,
        content=payload.content.strip(),
        created_at=datetime.now(UTC),
    )
    session.add(annotation)

    # Append to annotations_concat preserving raw_text untouched!
    current_annotations = capture.annotations_concat or ""
    addition = f"\n[Annotation]: {payload.content.strip()}"
    capture.annotations_concat = (current_annotations + addition).strip()
    capture.updated_at = datetime.now(UTC)
    session.add(capture)
    await session.commit()

    # Re-embed chunk 0 with updated annotations
    try:
        from app.workers.tasks import get_embedder

        embedder = get_embedder()
        title = capture.title or capture.extracted_title or "Untitled Note"
        full_text = f"{capture.raw_text or ''}\n\n{capture.annotations_concat}".strip()
        vec = await embedder.encode_text_document(title, full_text)

        upsert_stmt = (
            pg_insert(Embedding)
            .values(
                id=uuid.uuid4(),
                owner_id=capture_id,
                owner_table="captures",
                chunk_index=0,
                modality_composition="text",
                chunk_preview_text=full_text[:1200],
                token_count=len(full_text.split()),
                embedding=vec,
            )
            .on_conflict_do_update(
                index_elements=["owner_id", "owner_table", "chunk_index"],
                set_={
                    "chunk_preview_text": full_text[:1200],
                    "token_count": len(full_text.split()),
                    "embedding": vec,
                },
            )
        )
        await session.execute(upsert_stmt)
        await session.commit()
    except Exception as exc:
        logger.debug("Annotation embedding non-critical error: %s", exc)

    return {
        "status": "CREATED",
        "annotation_id": str(annotation_id),
        "capture_id": str(capture_id),
        "annotations_concat": capture.annotations_concat,
    }


@router.patch("/captures/{capture_id}/meta")
async def update_capture_meta(
    capture_id: UUID,
    payload: CaptureMetaUpdateRequest,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> dict[str, Any]:
    """Updates non-destructive metadata fields like user_tags, title, or page_range."""
    capture = await session.get(Capture, capture_id)
    if not capture or capture.is_deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Capture not found")

    if payload.title is not None:
        capture.title = payload.title
    if payload.user_tags is not None:
        capture.user_tags = payload.user_tags
    if payload.page_range is not None:
        capture.page_range = payload.page_range
    capture.updated_at = datetime.now(UTC)
    session.add(capture)
    await session.commit()
    return {"status": "UPDATED", "id": str(capture_id)}

