from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import col, select

from app.core.security import get_current_device
from app.db.session import get_async_session
from app.models.tables import AiSpark, Capture, Device, ReadingSession, Reminder
from app.schemas.sync import DeltaSyncResponse

router = APIRouter()


@router.get(
    "/sync/delta",
    response_model=DeltaSyncResponse,
    summary="Monotonic Delta Sync for Edge Clients",
)
async def get_sync_delta(
    since_version: int = Query(..., ge=0, description="Client's last known sync sequence cursor"),
    limit: int = Query(200, ge=1, le=1000, description="Max items per entity category"),
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> DeltaSyncResponse:
    # 1. Fetch captures with eager-loaded annotations and media assets
    cap_stmt = (
        select(Capture)
        .options(
            selectinload(Capture.annotations),  # type: ignore[arg-type]
            selectinload(Capture.media_assets),  # type: ignore[arg-type]
        )
        .where(col(Capture.sync_version) > since_version)
        .order_by(col(Capture.sync_version).asc())
        .limit(limit)
    )
    cap_res = await session.execute(cap_stmt)
    captures = cap_res.scalars().all()

    # 2. Fetch reading sessions
    rs_stmt = (
        select(ReadingSession)
        .where(col(ReadingSession.sync_version) > since_version)
        .order_by(col(ReadingSession.sync_version).asc())
        .limit(limit)
    )
    rs_res = await session.execute(rs_stmt)
    reading_sessions = rs_res.scalars().all()

    # 3. Fetch AI sparks
    spark_stmt = (
        select(AiSpark)
        .where(col(AiSpark.sync_version) > since_version)
        .order_by(col(AiSpark.sync_version).asc())
        .limit(limit)
    )
    spark_res = await session.execute(spark_stmt)
    ai_sparks = spark_res.scalars().all()

    # 4. Fetch reminders
    rem_stmt = (
        select(Reminder)
        .where(col(Reminder.sync_version) > since_version)
        .order_by(col(Reminder.sync_version).asc())
        .limit(limit)
    )
    rem_res = await session.execute(rem_stmt)
    reminders = rem_res.scalars().all()

    # 5. Determine maximum sync version across returned rows
    versions = [since_version]
    for c in captures:
        versions.append(c.sync_version)
    for rs in reading_sessions:
        versions.append(rs.sync_version)
    for sp in ai_sparks:
        versions.append(sp.sync_version)
    for r in reminders:
        versions.append(r.sync_version)

    current_max = max(versions)

    # 6. Format dictionaries for response
    captures_data = []
    for c in captures:
        c_dict = {
            "id": str(c.id),
            "reading_session_id": str(c.reading_session_id) if c.reading_session_id else None,
            "capture_type": c.capture_type.value,
            "processing_status": c.processing_status.value,
            "title": c.title,
            "raw_text": c.raw_text,
            "source_url": c.source_url,
            "page_range": c.page_range,
            "user_tags": c.user_tags,
            "extracted_title": c.extracted_title,
            "extracted_markdown": c.extracted_markdown,
            "ocr_text": c.ocr_text,
            "transcript_text": c.transcript_text,
            "auto_tags": c.auto_tags,
            "captured_at": c.captured_at.isoformat(),
            "updated_at": c.updated_at.isoformat(),
            "is_archived": c.is_archived,
            "is_deleted": c.is_deleted,
            "sync_version": c.sync_version,
            "annotations": [
                {
                    "id": str(a.id),
                    "content": a.content,
                    "created_at": a.created_at.isoformat(),
                    "sync_version": a.sync_version,
                }
                for a in c.annotations
            ],
            "media_assets": [
                {
                    "id": str(m.id),
                    "media_kind": m.media_kind,
                    "page_order": m.page_order,
                    "local_rel_path": m.local_rel_path,
                    "mime_type": m.mime_type,
                    "file_size_bytes": m.file_size_bytes,
                    "sha256_checksum": m.sha256_checksum,
                }
                for m in c.media_assets
            ],
        }
        captures_data.append(c_dict)

    reading_sessions_data = [
        {
            "id": str(rs.id),
            "source_title": rs.source_title,
            "author": rs.author,
            "isbn_or_url": rs.isbn_or_url,
            "default_tags": rs.default_tags,
            "is_active": rs.is_active,
            "created_at": rs.created_at.isoformat(),
            "updated_at": rs.updated_at.isoformat(),
            "sync_version": rs.sync_version,
        }
        for rs in reading_sessions
    ]

    ai_sparks_data = [
        {
            "id": str(sp.id),
            "title": sp.title,
            "spark_markdown": sp.spark_markdown,
            "spark_rationale": sp.spark_rationale,
            "related_project": sp.related_project,
            "tags": sp.tags,
            "model_id": sp.model_id,
            "is_read": sp.is_read,
            "is_pinned": sp.is_pinned,
            "is_dismissed": sp.is_dismissed,
            "created_at": sp.created_at.isoformat(),
            "updated_at": sp.updated_at.isoformat(),
            "sync_version": sp.sync_version,
        }
        for sp in ai_sparks
    ]

    reminders_data = [
        {
            "id": str(r.id),
            "target_id": str(r.target_id),
            "target_table": r.target_table,
            "reminder_type": r.reminder_type.value,
            "title": r.title,
            "message": r.message,
            "deep_link_uri": r.deep_link_uri,
            "scheduled_for": r.scheduled_for.isoformat(),
            "dispatched_at": r.dispatched_at.isoformat() if r.dispatched_at else None,
            "is_acknowledged": r.is_acknowledged,
            "sync_version": r.sync_version,
        }
        for r in reminders
    ]

    return DeltaSyncResponse(
        since_version=since_version,
        current_max_sync_version=current_max,
        has_more=(
            len(captures) == limit
            or len(reading_sessions) == limit
            or len(ai_sparks) == limit
            or len(reminders) == limit
        ),
        captures=captures_data,
        reading_sessions=reading_sessions_data,
        ai_sparks=ai_sparks_data,
        reminders=reminders_data,
    )
