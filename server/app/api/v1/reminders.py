from __future__ import annotations

import logging
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col, select

from app.core.security import get_current_device
from app.db.session import get_async_session
from app.models.tables import Device, Reminder

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Reminders"])


class ReminderAckRequest(BaseModel):
    is_acknowledged: bool = True
    snoozed_until: datetime | None = None


@router.patch("/reminders/{reminder_id}/ack", status_code=status.HTTP_200_OK)
async def acknowledge_or_snooze_reminder(
    reminder_id: uuid.UUID,
    payload: ReminderAckRequest,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> dict[str, str]:
    """Acknowledges a reminder or snoozes it to a future datetime."""
    reminder = await session.get(Reminder, reminder_id)
    if not reminder:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reminder not found")

    if payload.snoozed_until:
        # Snooze reschedules reminder and resets dispatch flag
        reminder.snoozed_until = payload.snoozed_until
        reminder.scheduled_for = payload.snoozed_until
        reminder.dispatched_at = None
        reminder.is_acknowledged = False
        action = "SNOOZED"
    else:
        reminder.is_acknowledged = payload.is_acknowledged
        action = "ACKNOWLEDGED"

    session.add(reminder)
    await session.commit()
    logger.info("Reminder %s %s from device %s", reminder_id, action, device.device_name)
    return {"status": "OK", "action": action, "reminder_id": str(reminder_id)}


@router.get("/reminders", response_model=list[Reminder])
async def list_reminders(
    include_acknowledged: bool = False,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> list[Reminder]:
    """Returns active/pending reminders."""
    stmt = select(Reminder)
    if not include_acknowledged:
        stmt = stmt.where(col(Reminder.is_acknowledged).is_(False))
    stmt = stmt.order_by(col(Reminder.scheduled_for).asc())
    res = await session.execute(stmt)
    return list(res.scalars().all())
