from __future__ import annotations

import logging
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col, select, update

from app.core.security import get_current_device
from app.db.session import get_async_session
from app.models.tables import Device, ReadingSession

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Reading Sessions"])


class ReadingSessionCreate(BaseModel):
    source_title: str = Field(..., max_length=512)
    author: str | None = Field(default=None, max_length=255)
    isbn_or_url: str | None = None
    default_tags: list[str] = Field(default_factory=list)
    is_active: bool = True


class ReadingSessionUpdate(BaseModel):
    source_title: str | None = None
    author: str | None = None
    isbn_or_url: str | None = None
    default_tags: list[str] | None = None
    is_active: bool | None = None


@router.post("/reading-sessions", response_model=ReadingSession, status_code=status.HTTP_201_CREATED)
async def create_reading_session(
    payload: ReadingSessionCreate,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> ReadingSession:
    """Creates a new active reading session for book scans and physical marginalia."""
    if payload.is_active:
        # Mark other reading sessions inactive
        await session.execute(
            update(ReadingSession).where(col(ReadingSession.is_active).is_(True)).values(is_active=False)
        )

    rs = ReadingSession(
        id=uuid.uuid4(),
        source_title=payload.source_title,
        author=payload.author,
        isbn_or_url=payload.isbn_or_url,
        default_tags=payload.default_tags,
        is_active=payload.is_active,
    )
    session.add(rs)
    await session.commit()
    await session.refresh(rs)
    return rs


@router.get("/reading-sessions", response_model=list[ReadingSession])
async def list_reading_sessions(
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> list[ReadingSession]:
    """Returns all reading sessions ordered by last updated."""
    stmt = select(ReadingSession).order_by(col(ReadingSession.updated_at).desc())
    res = await session.execute(stmt)
    return list(res.scalars().all())


@router.get("/reading-sessions/active", response_model=ReadingSession | None)
async def get_active_reading_session(
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> ReadingSession | None:
    """Returns the currently active sticky reading session if any."""
    stmt = (
        select(ReadingSession)
        .where(col(ReadingSession.is_active).is_(True))
        .order_by(col(ReadingSession.updated_at).desc())
        .limit(1)
    )
    res = await session.execute(stmt)
    return res.scalar_one_or_none()


@router.patch("/reading-sessions/{session_id}", response_model=ReadingSession)
async def update_reading_session(
    session_id: uuid.UUID,
    payload: ReadingSessionUpdate,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> ReadingSession:
    rs = await session.get(ReadingSession, session_id)
    if not rs:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reading session not found")

    if payload.is_active is True:
        await session.execute(
            update(ReadingSession).where(col(ReadingSession.is_active).is_(True)).values(is_active=False)
        )
        rs.is_active = True
    elif payload.is_active is False:
        rs.is_active = False

    if payload.source_title is not None:
        rs.source_title = payload.source_title
    if payload.author is not None:
        rs.author = payload.author
    if payload.isbn_or_url is not None:
        rs.isbn_or_url = payload.isbn_or_url
    if payload.default_tags is not None:
        rs.default_tags = payload.default_tags

    session.add(rs)
    await session.commit()
    await session.refresh(rs)
    return rs
