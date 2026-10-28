from __future__ import annotations

import logging
from datetime import UTC, datetime, time, timedelta
from uuid import UUID

import httpx
from sqlalchemy import func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col, select

from app.core.config import settings
from app.models.enums import ReminderTypeEnum
from app.models.tables import Reminder

logger = logging.getLogger(__name__)


def is_quiet_hours(now_local: time) -> bool:
    """Returns True if local time falls within quiet hours (22:30 to 08:00)."""
    return now_local >= time(22, 30) or now_local < time(8, 0)


def compute_quiet_hours_reschedule(current_dt: datetime) -> datetime:
    """Reschedules overnight reminders to the 08:30 morning brief."""
    if current_dt.time() >= time(22, 30):
        # Tomorrow at 08:30
        next_day = current_dt.date() + timedelta(days=1)
        return datetime.combine(next_day, time(8, 30), tzinfo=current_dt.tzinfo or UTC)
    else:
        # Today at 08:30
        return datetime.combine(current_dt.date(), time(8, 30), tzinfo=current_dt.tzinfo or UTC)


async def can_dispatch_non_urgent(
    session: AsyncSession,
    now_dt: datetime | None = None,
) -> bool:
    """Enforces daily cap of 3 non-urgent push notifications (CONTEXTUAL_MATCH / SPACED_REVIEW)."""
    ref_dt = now_dt or datetime.now(UTC)
    start_of_day = ref_dt.replace(hour=0, minute=0, second=0, microsecond=0)

    stmt = select(func.count(col(Reminder.id))).where(
        col(Reminder.dispatched_at) >= start_of_day,
        col(Reminder.reminder_type).in_(
            [ReminderTypeEnum.CONTEXTUAL_MATCH, ReminderTypeEnum.SPACED_REVIEW]
        ),
    )
    result = await session.execute(stmt)
    count = result.scalar() or 0
    return bool(count < 3)


async def publish_ntfy_reminder(
    ntfy_base_url: str,
    topic: str,
    reminder_id: UUID,
    title: str,
    message: str,
    deep_link_uri: str,
    ntfy_token: str | None = None,
    priority: int = 3,
    tags: list[str] | None = None,
) -> str:
    """Publishes a structured push notification to self-hosted ntfy broker."""
    headers: dict[str, str] = {
        "Title": title,
        "Priority": str(priority),
        "Tags": ",".join(tags or ["sparkles", "memo"]),
        "Click": deep_link_uri,
        "X-Reminder-Id": str(reminder_id),
    }
    if ntfy_token:
        headers["Authorization"] = f"Bearer {ntfy_token}"

    url = f"{ntfy_base_url.rstrip('/')}/{topic}"
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.post(url, content=message.encode("utf-8"), headers=headers)
        resp.raise_for_status()
        data = resp.json()
        return str(data.get("id") or "")


async def dispatch_due_reminders(
    session: AsyncSession,
    current_dt: datetime | None = None,
    ntfy_url_override: str | None = None,
) -> int:
    """Triage runner: inspects due reminders, checks quiet hours and daily caps, and dispatches to ntfy."""
    now = current_dt or datetime.now(UTC)
    now_time = now.time()

    stmt = (
        select(Reminder)
        .where(
            col(Reminder.scheduled_for) <= now,
            col(Reminder.dispatched_at).is_(None),
            col(Reminder.is_acknowledged).is_(False),
        )
        .order_by(col(Reminder.scheduled_for).asc())
    )
    res = await session.execute(stmt)
    due_reminders = list(res.scalars().all())

    dispatched_count = 0
    can_send_non_urgent = await can_dispatch_non_urgent(session, now)

    # Use internal URL or override
    base_url = ntfy_url_override or settings.NTFY_INTERNAL_URL
    topic = settings.NTFY_TOPIC

    for rem in due_reminders:
        is_explicit = rem.reminder_type == ReminderTypeEnum.TIME_SCHEDULED

        # 1. Quiet Hours check
        if is_quiet_hours(now_time) and not is_explicit:
            # Non-urgent reminders deferred to morning brief
            rem.scheduled_for = compute_quiet_hours_reschedule(now)
            session.add(rem)
            continue

        # 2. Daily Notification Cap
        if not is_explicit and not can_send_non_urgent:
            # Defer non-urgent to tomorrow 08:30
            rem.scheduled_for = compute_quiet_hours_reschedule(now)
            session.add(rem)
            continue

        # 3. Publish to ntfy
        priority = 4 if is_explicit else 3
        try:
            msg_id = await publish_ntfy_reminder(
                ntfy_base_url=base_url,
                topic=topic,
                reminder_id=rem.id,
                title=rem.title,
                message=rem.message,
                deep_link_uri=rem.deep_link_uri,
                ntfy_token=settings.NTFY_ACCESS_TOKEN or None,
                priority=priority,
            )
            rem.ntfy_message_id = msg_id
            rem.dispatched_at = now
            session.add(rem)
            dispatched_count += 1
            if not is_explicit:
                can_send_non_urgent = await can_dispatch_non_urgent(session, now)
        except Exception as exc:
            logger.error("Failed to publish reminder %s to ntfy: %s", rem.id, exc)

    await session.commit()
    return dispatched_count
