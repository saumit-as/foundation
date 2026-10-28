# 07_REMINDER_AND_PUSH_SPEC.md
> **INTELLIGENT REMINDER TRIAGE & SELF-HOSTED `ntfy` PUSH SPECIFICATION**
> This document defines how reminders are scheduled, triaged to prevent notification fatigue, dispatched via the self-hosted `ntfy` container, and consumed natively by the Flutter and Desktop clients **without requiring the third-party `ntfy` app**.

---

## 1. Anti-Fatigue Triage Rules (`app/services/notifier.py`)

Dumping links and reels into a scratchpad quickly leads to notification blindness if every item triggers an alert. The reminder engine enforces three triage guardrails:

1. **Daily Notification Budget:** Maximum of **3 non-urgent push notifications per day** (`CONTEXTUAL_MATCH` + `SPACED_REVIEW`). Explicit user reminders (`"remind me tonight at 8pm"`) bypass this cap.
2. **Quiet Hours Enforcement:** Never dispatch push notifications between `22:30` and `08:00` local time unless marked `priority = 5 (urgent)`. Queued night-time sparks are bundled into a single `08:30 AM` morning brief.
3. **Three Reminder Triggers:**
   - **`TIME_SCHEDULED`:** User note contains temporal intent (e.g., *"look into this weekend"*, *"read before Friday"*), parsed by `gpt-6-luna` into `scheduled_for`.
   - **`CONTEXTUAL_MATCH`:** User captures a new thought that has cosine similarity $\ge 0.80$ with an **unread** `article_url` or `video_reel` saved $>3$ days ago. Fires a push: *"You saved a Reel last week that directly relates to what you just wrote."*
   - **`SPACED_REVIEW`:** Unread saved articles/reels matching an active project are surfaced at `+2 days` and `+7 days`; if ignored twice, they are auto-archived cleanly without further nagging.

---

## 2. Self-Hosted `ntfy` Publisher Contract (Server -> `ntfy` Container)

The `ntfy` server runs inside the Docker Compose network at `http://ntfy:80` and is exposed through the Cloudflare Tunnel at `https://api.<your-domain>.com/ntfy` (protected by Cloudflare Access Service Tokens + `ntfy` Bearer ACLs).

### 2.1 Publishing a Notification from Python (`app/services/notifier.py`)
```python
import httpx
from uuid import UUID


async def publish_ntfy_reminder(
    ntfy_base_url: str,
    ntfy_token: str,
    topic: str,
    reminder_id: UUID,
    title: str,
    message: str,
    deep_link_uri: str,
    priority: int = 3,
    tags: list[str] | None = None,
) -> str:
    """Publish structured push notification to self-hosted ntfy broker."""
    headers = {
        "Authorization": f"Bearer {ntfy_token}",
        "Title": title,
        "Priority": str(priority),
        "Tags": ",".join(tags or ["sparkles", "memo"]),
        "Click": deep_link_uri,
        "X-Reminder-Id": str(reminder_id),
    }
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.post(
            f"{ntfy_base_url}/{topic}",
            content=message.encode("utf-8"),
            headers=headers,
        )
        resp.raise_for_status()
        data = resp.json()
        return data["id"]  # Stored in reminders.ntfy_message_id
```

---

## 3. Native Client Consumption (Without the Third-Party `ntfy` App)

### 3.1 Flutter App (`Android`, `Linux`, `Windows`)
Located in `app_client/lib/data/sync/ntfy_listener_service.dart`:
1. **Live WebSocket Stream (When App is Open or in Desktop System Tray):**
   - Connects to `wss://api.<your-domain>.com/ntfy/<topic>/ws?since=<last_ntfy_id>` with headers:
     - `CF-Access-Client-Id`
     - `CF-Access-Client-Secret`
     - `Authorization: Bearer <ntfy_token>`
   - Parses incoming JSON envelopes (`event == "message"`), extracting `title`, `message`, `click` (`deep_link_uri`), and custom header `X-Reminder-Id`.
   - Immediately triggers an OS-native notification via `flutter_local_notifications` with the `deep_link_uri` payload (`scratchpad://spark/<uuid>` or `scratchpad://capture/<uuid>`) and registers two native OS action buttons (`Mark Done` and `Snooze 3h`).
   - **Authenticated Action Callback (Offline-Safe):** When the user taps `Mark Done` or `Snooze 3h` on the notification, `flutter_local_notifications` invokes the Dart background callback, which calls `PATCH /api/v1/reminders/{reminder_id}/ack` using the app's authenticated `Dio` client (injecting `CF-Access-Client-Id`, `CF-Access-Client-Secret`, and `Authorization: Bearer <device_key>` from `flutter_secure_storage`), or writes an `ACK_REMINDER` operation into `OutboxSyncQueue` if offline. This avoids embedding Zero-Trust secrets inside raw `ntfy` payloads.
   - Saves `data["id"]` to `SyncStateMeta` (`last_ntfy_message_id`) so messages are never duplicated.
2. **Android Background Reliability (`WorkManager` + Optional Foreground Service):**
   - Because Android kills background WebSockets when the screen is off, the Flutter app registers a periodic `WorkManager` task (every 15 minutes when on network) that calls:
     `GET https://api.<your-domain>.com/ntfy/<topic>/json?since=<last_ntfy_id>&poll=1`
   - Any missed messages are rendered immediately via `flutter_local_notifications` and trigger a fast delta sync (`/api/v1/sync/delta`).
   - Users also have a Settings toggle for *"Instant Real-Time Background Push (Persistent Service)"* if they want 0-second background latency on Android.

### 3.2 Optional Linux Lightweight Daemon (`systemd --user`)
For Linux desktop environments (e.g., Hyprland / Sway / GNOME) when the Flutter GUI window is closed, a lightweight shell or Python listener can subscribe and pipe to `notify-send`:
```bash
curl -sN \
  -H "CF-Access-Client-Id: ${CF_ID}" \
  -H "CF-Access-Client-Secret: ${CF_SECRET}" \
  -H "Authorization: Bearer ${NTFY_TOKEN}" \
  "https://api.${DOMAIN}/ntfy/${TOPIC}/json" | while read -r line; do
    title=$(echo "$line" | jq -r 'select(.event=="message") | .title // "Scratchpad"')
    msg=$(echo "$line" | jq -r 'select(.event=="message") | .message // empty')
    [ -n "$msg" ] && notify-send "$title" "$msg"
done
```