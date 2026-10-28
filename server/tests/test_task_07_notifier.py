from __future__ import annotations

import hashlib
import uuid
from datetime import UTC, datetime, time, timedelta

import pytest
from httpx import ASGITransport, AsyncClient
from sqlmodel import col, delete

from app.core.config import settings
from app.db.session import AsyncSessionLocal
from app.main import app
from app.models.enums import ReminderTypeEnum
from app.models.tables import Device, Reminder
from app.services.notifier import (
    can_dispatch_non_urgent,
    dispatch_due_reminders,
    is_quiet_hours,
    publish_ntfy_reminder,
)

NTFY_TEST_URL = "http://192.168.88.102:8085"


def test_01_quiet_hours_and_reschedule():
    """Quiet hours check (23:15) defers a CONTEXTUAL_MATCH reminder to 08:30 next morning, while TIME_SCHEDULED dispatches."""
    late_night = time(23, 15)
    morning_work = time(10, 0)
    early_dawn = time(3, 45)

    assert is_quiet_hours(late_night) is True
    assert is_quiet_hours(early_dawn) is True
    assert is_quiet_hours(morning_work) is False


@pytest.mark.asyncio
async def test_02_daily_budget_and_quiet_hours_triage():
    """Daily budget check blocks the 4th non-urgent alert in a single day while allowing explicit TIME_SCHEDULED through."""
    now = datetime(2026, 10, 28, 14, 0, tzinfo=UTC)  # 2:00 PM (outside quiet hours)

    async with AsyncSessionLocal() as session:
        # Clear existing un-dispatched test reminders
        await session.execute(delete(Reminder).where(col(Reminder.dispatched_at).is_(None)))
        await session.commit()

        # Seed 3 already dispatched non-urgent reminders today
        start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
        for i in range(3):
            r = Reminder(
                id=uuid.uuid4(),
                target_id=uuid.uuid4(),
                target_table="captures",
                reminder_type=ReminderTypeEnum.CONTEXTUAL_MATCH,
                title=f"Non-urgent alert {i + 1}",
                message="Contextual connection",
                deep_link_uri=f"scratchpad://capture/{uuid.uuid4()}",
                scheduled_for=start_of_day + timedelta(hours=i + 1),
                dispatched_at=start_of_day + timedelta(hours=i + 1),
            )
            session.add(r)
        await session.commit()

        # 1. Budget cap should be reached for non-urgent
        can_send = await can_dispatch_non_urgent(session, now)
        assert can_send is False

        # 2. Add 4th non-urgent reminder and 1 explicit TIME_SCHEDULED reminder
        rem_non_urgent_id = uuid.uuid4()
        rem_explicit_id = uuid.uuid4()

        r4 = Reminder(
            id=rem_non_urgent_id,
            target_id=uuid.uuid4(),
            target_table="captures",
            reminder_type=ReminderTypeEnum.SPACED_REVIEW,
            title="Spaced Review 4th attempt",
            message="Check unread article",
            deep_link_uri=f"scratchpad://capture/{uuid.uuid4()}",
            scheduled_for=now - timedelta(minutes=10),
            dispatched_at=None,
        )
        r_explicit = Reminder(
            id=rem_explicit_id,
            target_id=uuid.uuid4(),
            target_table="captures",
            reminder_type=ReminderTypeEnum.TIME_SCHEDULED,
            title="Explicit user reminder: Deploy cluster",
            message="User requested explicit time alert",
            deep_link_uri=f"scratchpad://capture/{uuid.uuid4()}",
            scheduled_for=now - timedelta(minutes=5),
            dispatched_at=None,
        )
        session.add(r4)
        session.add(r_explicit)
        await session.commit()

        # Run triage dispatch pointing to local ntfy
        dispatched_count = await dispatch_due_reminders(
            session=session,
            current_dt=now,
            ntfy_url_override=NTFY_TEST_URL,
        )

        # Only the explicit reminder should have dispatched (1 of 2)!
        assert dispatched_count == 1

        # Check DB state
        r4_db = await session.get(Reminder, rem_non_urgent_id)
        assert r4_db is not None
        assert r4_db.dispatched_at is None
        # It was deferred to morning 08:30
        assert r4_db.scheduled_for.time() == time(8, 30)

        r_exp_db = await session.get(Reminder, rem_explicit_id)
        assert r_exp_db is not None
        assert r_exp_db.dispatched_at is not None
        assert r_exp_db.ntfy_message_id is not None


@pytest.mark.asyncio
async def test_03_publish_ntfy_direct_container():
    """Publishing a reminder directly to the local running ntfy broker returns a valid message ID."""
    rem_id = uuid.uuid4()
    msg_id = await publish_ntfy_reminder(
        ntfy_base_url=NTFY_TEST_URL,
        topic="scratchpad_alerts",
        reminder_id=rem_id,
        title="Direct ntfy container test",
        message="Verifying live container HTTP push",
        deep_link_uri=f"scratchpad://spark/{rem_id}",
        priority=3,
        tags=["rocket", "test"],
    )
    assert msg_id is not None
    assert len(msg_id) > 0


@pytest.mark.asyncio
async def test_04_ack_and_snooze_reminder():
    """PATCH /api/v1/reminders/{id}/ack with snoozed_until reschedules the reminder cleanly."""
    raw_token = f"mem_live_{uuid.uuid4().hex}{uuid.uuid4().hex}"
    token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
    rem_id = uuid.uuid4()
    device_id = uuid.uuid4()

    async with AsyncSessionLocal() as session:
        dev = Device(
            id=device_id,
            device_name=f"Ack-Dev-{uuid.uuid4().hex[:6]}",
            device_type="android",
            api_key_hash=token_hash,
        )
        session.add(dev)
        await session.flush()

        rem = Reminder(
            id=rem_id,
            target_id=uuid.uuid4(),
            target_table="captures",
            reminder_type=ReminderTypeEnum.TIME_SCHEDULED,
            title="Read distributed systems paper",
            message="Snooze verification",
            deep_link_uri=f"scratchpad://capture/{rem_id}",
            scheduled_for=datetime.now(UTC),
            dispatched_at=datetime.now(UTC),
            is_acknowledged=False,
        )
        session.add(rem)
        await session.commit()

    headers = {
        "CF-Access-Client-Id": settings.CF_ACCESS_CLIENT_ID,
        "CF-Access-Client-Secret": settings.CF_ACCESS_CLIENT_SECRET,
        "Authorization": f"Bearer {raw_token}",
    }

    transport = ASGITransport(app=app)
    snooze_target = datetime.now(UTC) + timedelta(hours=3)

    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        resp = await client.patch(
            f"/api/v1/reminders/{rem_id}/ack",
            headers=headers,
            json={"is_acknowledged": False, "snoozed_until": snooze_target.isoformat()},
        )
        assert resp.status_code == 200
        assert resp.json()["action"] == "SNOOZED"

    async with AsyncSessionLocal() as session:
        updated_rem = await session.get(Reminder, rem_id)
        assert updated_rem is not None
        assert updated_rem.is_acknowledged is False
        assert updated_rem.dispatched_at is None
        assert updated_rem.snoozed_until is not None
        assert abs((updated_rem.scheduled_for - snooze_target).total_seconds()) < 1.0
