import logging

from fastapi import APIRouter, Depends, status
from redis.asyncio import from_url as redis_from_url
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col, select

from app.core.config import settings
from app.core.security import get_current_device
from app.db.session import get_async_session
from app.models.enums import CaptureTypeEnum, ProcessingStatusEnum
from app.models.tables import Capture, Device, ReadingSession
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
