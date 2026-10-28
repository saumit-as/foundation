from __future__ import annotations

import logging
import os
from pathlib import Path
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col, select

from app.core.config import settings
from app.core.security import get_current_device
from app.db.session import get_async_session
from app.models.enums import ProcessingStatusEnum
from app.models.tables import Capture, Device
from app.schemas.capture import CaptureResponse
from app.workers.tasks import job_ingest_capture

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Scraper & Rescue"])


class CookiePayload(BaseModel):
    cookie_content: str = Field(..., description="Netscape formatted cookies.txt content")


class RescuePayload(BaseModel):
    dom_fallback_markdown: str = Field(..., description="Rendered HTML DOM text/markdown from browser")
    title: str | None = Field(default=None, description="Optional article title extracted from browser DOM")


@router.post("/scraper/cookies", status_code=status.HTTP_200_OK)
async def upload_cookies(
    payload: CookiePayload,
    current_device: Device = Depends(get_current_device),
) -> dict[str, str]:
    """Syncs Netscape cookies from browser extension to bypass video login walls."""
    cookie_dir = Path(settings.MEDIA_ROOT) / ".cookies"
    cookie_dir.mkdir(parents=True, exist_ok=True)
    cookie_file = cookie_dir / "cookies.txt"

    cookie_file.write_text(payload.cookie_content, encoding="utf-8")
    os.chmod(cookie_file, 0o600)

    logger.info("Updated cookies.txt from device %s (%d bytes)", current_device.device_name, len(payload.cookie_content))
    return {"status": "ok", "path": str(cookie_file)}


@router.get("/captures/partial", response_model=list[CaptureResponse])
async def list_partial_captures(
    session: AsyncSession = Depends(get_async_session),
    current_device: Device = Depends(get_current_device),
) -> list[Capture]:
    """Returns all captures stuck in EXTRACTION_PARTIAL status for the browser extension Rescue Queue."""
    stmt = (
        select(Capture)
        .where(
            col(Capture.processing_status) == ProcessingStatusEnum.EXTRACTION_PARTIAL,
            col(Capture.is_deleted).is_(False),
        )
        .order_by(col(Capture.captured_at).desc())
    )
    result = await session.execute(stmt)
    return list(result.scalars().all())


@router.post("/captures/{capture_id}/rescue", status_code=status.HTTP_202_ACCEPTED)
async def rescue_partial_capture(
    capture_id: UUID,
    payload: RescuePayload,
    session: AsyncSession = Depends(get_async_session),
    current_device: Device = Depends(get_current_device),
) -> dict[str, str]:
    """1-Click Browser Rescue: replaces failed scrape with rendered DOM markdown and re-triggers ingestion."""
    capture = await session.get(Capture, capture_id)
    if not capture or capture.is_deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Capture not found")

    capture.extracted_markdown = payload.dom_fallback_markdown
    if payload.title:
        capture.extracted_title = payload.title
    capture.processing_status = ProcessingStatusEnum.QUEUED
    session.add(capture)
    await session.commit()

    # Trigger background re-ingestion
    try:
        await job_ingest_capture.kiq(str(capture_id))
    except Exception as exc:
        logger.debug("Taskiq kiq enqueue: %s", exc)

    logger.info("Rescued capture %s via browser extension DOM payload", capture_id)
    return {"status": "accepted", "capture_id": str(capture_id)}
