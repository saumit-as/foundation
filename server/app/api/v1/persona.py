from __future__ import annotations

import logging
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col, select

from app.core.security import get_current_device
from app.db.session import get_async_session
from app.models.tables import Device, PersonaSnapshot

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Persona Profile"])


@router.get("/persona")
async def get_current_persona(
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> dict[str, Any]:
    """Returns the current user persona snapshot and preferences."""
    stmt = (
        select(PersonaSnapshot)
        .where(col(PersonaSnapshot.is_current).is_(True))
        .order_by(col(PersonaSnapshot.version_number).desc())
        .limit(1)
    )
    res = await session.execute(stmt)
    snapshot = res.scalar_one_or_none()
    if not snapshot:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No current persona snapshot found. Please seed initial persona.",
        )
    return {
        "version_number": snapshot.version_number,
        "is_current": snapshot.is_current,
        "persona_json": snapshot.persona_json,
        "created_at": snapshot.created_at.isoformat() if snapshot.created_at else None,
    }
