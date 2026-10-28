from __future__ import annotations

import logging
import uuid
from typing import Any, Literal

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col, select

from app.core.security import get_current_device
from app.db.session import get_async_session
from app.models.tables import AISpark, Capture, Device

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Daily Triage Deck"])


class TriageDeckItem(BaseModel):
    item_id: uuid.UUID
    item_table: Literal["captures", "ai_sparks"]
    title: str | None
    snippet: str
    captured_at: str
    tags: list[str] = []


class TriageDecisionRequest(BaseModel):
    decision: Literal["KEEP", "PIN_TO_PROJECT", "ARCHIVE", "DISMISS"]
    project_slug: str | None = Field(default=None, description="Active project slug for PIN_TO_PROJECT")


@router.get("/triage/deck", response_model=list[TriageDeckItem])
async def get_triage_deck(
    limit: int = 20,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> list[TriageDeckItem]:
    """Returns items needing daily triage (morning/evening review deck)."""
    items: list[TriageDeckItem] = []

    # Unreviewed captures
    cap_stmt = (
        select(Capture)
        .where(
            col(Capture.is_triage_reviewed).is_(False),
            col(Capture.is_deleted).is_(False),
            col(Capture.is_archived).is_(False),
        )
        .order_by(col(Capture.captured_at).desc())
        .limit(limit)
    )
    cap_res = await session.execute(cap_stmt)
    for c in cap_res.scalars().all():
        snippet = (c.raw_text or c.extracted_markdown or c.ocr_text or "")[:300]
        items.append(
            TriageDeckItem(
                item_id=c.id,
                item_table="captures",
                title=c.title or c.extracted_title or "Quick Capture",
                snippet=snippet,
                captured_at=c.captured_at.isoformat() if c.captured_at else "",
                tags=c.user_tags or [],
            )
        )

    # Active unreviewed sparks
    spark_stmt = (
        select(AISpark)
        .where(
            col(AISpark.is_dismissed).is_(False),
            col(AISpark.is_pinned).is_(False),
        )
        .order_by(col(AISpark.created_at).desc())
        .limit(limit)
    )
    spark_res = await session.execute(spark_stmt)
    for s in spark_res.scalars().all():
        items.append(
            TriageDeckItem(
                item_id=s.id,
                item_table="ai_sparks",
                title=s.title,
                snippet=s.spark_markdown[:300],
                captured_at=s.created_at.isoformat() if s.created_at else "",
                tags=[s.related_project] if s.related_project else [],
            )
        )

    return items[:limit]


@router.post("/triage/{item_id}/decision", status_code=status.HTTP_200_OK)
async def submit_triage_decision(
    item_id: uuid.UUID,
    payload: TriageDecisionRequest,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> dict[str, Any]:
    """Applies user triage decision (KEEP, PIN_TO_PROJECT, ARCHIVE, DISMISS)."""
    # 1. Check captures first
    capture = await session.get(Capture, item_id)
    if capture:
        if payload.decision == "KEEP":
            capture.is_triage_reviewed = True
        elif payload.decision == "PIN_TO_PROJECT":
            capture.is_triage_reviewed = True
            if payload.project_slug:
                tags = set(capture.user_tags or [])
                tags.add(payload.project_slug)
                capture.user_tags = list(tags)
        elif payload.decision == "ARCHIVE" or payload.decision == "DISMISS":
            capture.is_triage_reviewed = True
            capture.is_archived = True

        session.add(capture)
        await session.commit()
        return {"status": "OK", "item_id": str(item_id), "decision": payload.decision}

    # 2. Check sparks
    spark = await session.get(AISpark, item_id)
    if spark:
        if payload.decision == "KEEP":
            pass
        elif payload.decision == "PIN_TO_PROJECT":
            spark.is_pinned = True
            if payload.project_slug:
                spark.related_project = payload.project_slug
        elif payload.decision in ("ARCHIVE", "DISMISS"):
            spark.is_dismissed = True

        session.add(spark)
        await session.commit()
        return {"status": "OK", "item_id": str(item_id), "decision": payload.decision}

    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")
