# 07_NTFY_REMINDER_TRIAGE_AND_CLOUDFLARE_TUNNEL.md
> **TASK 07: ANTI-FATIGUE `ntfy` PUSH ENGINE, SERVER DOCKERFILE & CLOUDFLARE ZERO-TRUST TUNNEL**
> - **Prerequisites:** Task 06 `[x] PASSED`
> - **Reference Spec:** [`docs/07_reminder_triage_and_push_notification_spec.md`](../docs/07_reminder_triage_and_push_notification_spec.md) and [`docs/09_infrastructure_and_cloudflare_tunnel_deployment.md`](../docs/09_infrastructure_and_cloudflare_tunnel_deployment.md)

---

## 1. Objective
Implement the anti-fatigue push notification service (`server/app/services/notifier.py`) enforcing the **3 non-urgent alerts/day cap**, **quiet hours (`22:30–08:00`) morning bundler**, and **3 reminder triggers** (`TIME_SCHEDULED`, `CONTEXTUAL_MATCH`, `SPACED_REVIEW`), plus `/api/v1/reminders/{id}/ack`. Create `server/Dockerfile` and verify the complete multi-container stack (`postgres`, `redis`, `server-api`, `server-worker`, `ntfy`, `cloudflared`).

---

## 2. Exact Files to Create / Update

1. `server/app/services/notifier.py`
2. `server/app/api/v1/reminders.py`
3. `server/app/workers/tasks.py` *(add `job_dispatch_due_reminders` periodic task running every 60s)*
4. `server/app/main.py` *(register `/api/v1/reminders` router and `/healthz` endpoint)*
5. `server/Dockerfile`
6. `server/tests/test_task_07_notifier.py`

---

## 3. Step-by-Step Implementation Instructions

### Step 3.1: Implement Anti-Fatigue Triage & `ntfy` Publisher (`server/app/services/notifier.py`)
Follow `docs/07_reminder_triage_and_push_notification_spec.md` Sections 1 & 2:
1. **Quiet Hours Guard (`is_quiet_hours(now_local: time) -> bool`):**
   - Returns `True` if `now_local >= time(22, 30)` or `now_local < time(8, 0)`.
   - If a non-urgent reminder (`priority < 5`) becomes due during quiet hours, reschedule its `scheduled_for` to `08:30:00` local time so overnight sparks bundle into a morning brief.
2. **Daily Notification Budget (`can_dispatch_non_urgent(session: AsyncSession) -> bool`):**
   - Queries `count(*)` from `reminders` where `dispatched_at >= start_of_today_local` and `reminder_type IN ('CONTEXTUAL_MATCH', 'SPACED_REVIEW')`.
   - If `count >= 3`, defer non-urgent reminders to tomorrow's triage deck (`TIME_SCHEDULED` explicit user reminders bypass this cap).
3. **`publish_ntfy_reminder(...) -> str`:**
   - Sends `POST {ntfy_base_url}/{topic}` with headers `Authorization: Bearer {ntfy_token}`, `Title`, `Priority`, `Tags`, `Click: {deep_link_uri}`, and `X-Reminder-Id: {reminder_id}` (no unauthenticated HTTP action URLs; actions are handled natively by the Flutter app's authenticated Dio client).
   - Stores returned `data["id"]` in `reminders.ntfy_message_id` and sets `dispatched_at = NOW()`.

### Step 3.2: Implement `PATCH /api/v1/reminders/{id}/ack` (`server/app/api/v1/reminders.py`)
- Updates `is_acknowledged = payload.is_acknowledged` and `snoozed_until = payload.snoozed_until` (if snoozed, clears `dispatched_at = None` and sets `scheduled_for = payload.snoozed_until` so it fires again when the snooze expires).

### Step 3.3: Create `server/Dockerfile`
Create a clean Python 3.12 + `uv` + `ffmpeg` + `tesseract-ocr` Dockerfile for `server-api` and `server-worker`:
```dockerfile
FROM python:3.12-slim-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg tesseract-ocr libgl1 libglib2.0-0 curl postgresql-client \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-install-project

COPY . .
EXPOSE 8000
```

---

## 4. `[USER INTERVENTION REQUIRED]` Checkpoint (Cloudflare Tunnel Token)

Before starting `cloudflared` in Docker Compose, if `CLOUDFLARE_TUNNEL_TOKEN` in `infra/.env` is still a placeholder, pause and display:

```text
[USER INTERVENTION REQUIRED — TASK 07 (OPTIONAL FOR LOCAL DEV, REQUIRED FOR WAN)]
To expose your home server over Cloudflare Zero Trust:
1. In Cloudflare Zero Trust Dashboard -> Networks -> Tunnels, create a tunnel and copy the token into `infra/.env` as `CLOUDFLARE_TUNNEL_TOKEN=...`.
2. Route Public Hostname `api.<yourdomain>.com` -> `http://server-api:8000` and `api.<yourdomain>.com/ntfy*` -> `http://ntfy:80`.
3. Create an Access Service Token (`CF-Access-Client-Id` & `CF-Access-Client-Secret`) and add them to `infra/.env`.
(If testing locally on LAN/localhost first, reply "continue local" and we will verify against the local ntfy & FastAPI containers.)
```

---

## 5. Deterministic Verification Gate (`PASS / FAIL`)

Write `server/tests/test_task_07_notifier.py` verifying:
1. Quiet hours check (`23:15` local time) defers a `CONTEXTUAL_MATCH` reminder to `08:30` the next morning, whereas a `TIME_SCHEDULED` priority-5 reminder dispatches immediately.
2. Daily budget check blocks the 4th `CONTEXTUAL_MATCH` / `SPACED_REVIEW` notification in a single day while allowing an explicit `TIME_SCHEDULED` reminder through.
3. Publishing a reminder to the running local `ntfy` container (`http://127.0.0.1:8085/scratchpad_alerts`) returns a valid `ntfy_message_id` and stores it in `reminders.ntfy_message_id`.
4. `PATCH /api/v1/reminders/{id}/ack` with `snoozed_until` reschedules the reminder cleanly.

Run:
```powershell
cd server
uv run ruff check .
uv run mypy app
uv run pytest tests/test_task_07_notifier.py -v
```
- **Success Criteria:** `0` lint/type errors and `4 passed` in pytest (exit code `0`). Mark **Task 07** as `[x] PASSED` in `tasks/00_TASK_RUNNER_AND_INDEX.md`.
