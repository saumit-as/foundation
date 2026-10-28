import hashlib
import uuid
from datetime import UTC, datetime

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select

from app.cli import register_device, seed_persona
from app.db.session import AsyncSessionLocal
from app.main import app
from app.models.tables import Capture, Device, PersonaSnapshot


@pytest.mark.asyncio
async def test_01_cli_register_and_seed_persona():
    # 1. Test seed_persona
    await seed_persona(None)
    async with AsyncSessionLocal() as session:
        res = await session.execute(
            select(PersonaSnapshot).where(PersonaSnapshot.is_current.is_(True))
        )
        snapshot = res.scalar_one_or_none()
        assert snapshot is not None
        assert snapshot.version_number >= 1
        assert len(snapshot.cached_prompt_prefix) >= 4200

    # 2. Test register_device
    device_name = f"Test-Device-{uuid.uuid4().hex[:6]}"
    await register_device(device_name, "android", show_qr=False)
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(Device).where(Device.device_name == device_name))
        device = res.scalar_one_or_none()
        assert device is not None
        assert device.is_revoked is False
        assert len(device.api_key_hash) == 64


@pytest.mark.asyncio
async def test_02_unauthenticated_request_rejected():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get("/api/v1/sync/delta?since_version=0")
        assert response.status_code == 401
        assert "detail" in response.json()


@pytest.mark.asyncio
async def test_03_capture_instant_and_idempotency():
    # Provision a test device
    raw_token = f"mem_live_{uuid.uuid4().hex}{uuid.uuid4().hex}"
    token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
    test_device_id = uuid.uuid4()

    async with AsyncSessionLocal() as session:
        device = Device(
            id=test_device_id,
            device_name="Test-Capture-Runner",
            device_type="android",
            api_key_hash=token_hash,
        )
        session.add(device)
        await session.commit()

    headers = {"Authorization": f"Bearer {raw_token}"}
    capture_id = uuid.uuid4()
    now_iso = datetime.now(UTC).isoformat()
    payload = {
        "id": str(capture_id),
        "capture_type": "text_note",
        "title": "Idempotency Test Note",
        "raw_text": "Testing fast capture SLA and idempotent double-post",
        "source_url": "https://example.com/test",
        "user_tags": ["test", "idempotency"],
        "captured_at": now_iso,
    }

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # First submission -> 202 Accepted
        resp1 = await ac.post("/api/v1/capture", json=payload, headers=headers)
        assert resp1.status_code == 202
        data1 = resp1.json()
        assert data1["status"] == "ACCEPTED"
        assert data1["id"] == str(capture_id)
        assert data1["sync_version"] >= 1

        # Second submission with EXACT SAME UUIDv7 -> 202 Accepted (idempotent no-op)
        resp2 = await ac.post("/api/v1/capture", json=payload, headers=headers)
        assert resp2.status_code == 202
        data2 = resp2.json()
        assert data2["status"] == "ACCEPTED"
        assert data2["id"] == str(capture_id)

    # Verify database has exactly 1 record for this UUID
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(Capture).where(Capture.id == capture_id))
        records = res.scalars().all()
        assert len(records) == 1
        assert records[0].title == "Idempotency Test Note"


@pytest.mark.asyncio
async def test_04_media_upload_sha256_and_range_streaming():
    raw_token = f"mem_live_{uuid.uuid4().hex}{uuid.uuid4().hex}"
    token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
    test_device_id = uuid.uuid4()

    capture_id = uuid.uuid4()
    async with AsyncSessionLocal() as session:
        device = Device(
            id=test_device_id,
            device_name="Test-Media-Runner",
            device_type="android",
            api_key_hash=token_hash,
        )
        session.add(device)
        await session.commit()

        capture = Capture(
            id=capture_id,
            device_id=test_device_id,
            capture_type="book_scan",
            captured_at=datetime.now(UTC),
        )
        session.add(capture)
        await session.commit()

    headers = {"Authorization": f"Bearer {raw_token}"}
    sample_content = b"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    actual_hash = hashlib.sha256(sample_content).hexdigest()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # 1. Upload with invalid sha256 -> 400 Bad Request
        files = {"file": ("test_page.bin", sample_content, "application/octet-stream")}
        data = {
            "media_kind": "book_page",
            "sha256_checksum": "0000000000000000000000000000000000000000000000000000000000000000",
            "page_order": 0,
            "soft_token_budget": 1120,
        }
        bad_resp = await ac.post(
            f"/api/v1/capture/{capture_id}/media",
            files=files,
            data=data,
            headers=headers,
        )
        assert bad_resp.status_code == 400

        # 2. Upload with valid sha256 -> 201 Created
        files = {"file": ("test_page.bin", sample_content, "application/octet-stream")}
        data["sha256_checksum"] = actual_hash
        good_resp = await ac.post(
            f"/api/v1/capture/{capture_id}/media",
            files=files,
            data=data,
            headers=headers,
        )
        assert good_resp.status_code == 201
        asset_info = good_resp.json()
        asset_id = asset_info["asset_id"]
        assert asset_info["file_size_bytes"] == len(sample_content)

        # 3. Stream range request: bytes=0-15
        range_headers = {
            "Authorization": f"Bearer {raw_token}",
            "Range": "bytes=0-15",
        }
        stream_resp = await ac.get(f"/api/v1/media/{asset_id}", headers=range_headers)
        assert stream_resp.status_code == 206
        assert stream_resp.headers["Content-Range"] == f"bytes 0-15/{len(sample_content)}"
        assert stream_resp.headers["Content-Length"] == "16"
        assert stream_resp.content == sample_content[0:16]


@pytest.mark.asyncio
async def test_05_delta_sync():
    raw_token = f"mem_live_{uuid.uuid4().hex}{uuid.uuid4().hex}"
    token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
    test_device_id = uuid.uuid4()

    async with AsyncSessionLocal() as session:
        device = Device(
            id=test_device_id,
            device_name="Test-Sync-Runner",
            device_type="linux",
            api_key_hash=token_hash,
        )
        session.add(device)
        await session.commit()

    headers = {"Authorization": f"Bearer {raw_token}"}
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # Create a capture first so delta sync has data
        cap_id = str(uuid.uuid4())
        await ac.post(
            "/api/v1/capture",
            json={
                "id": cap_id,
                "capture_type": "text_note",
                "title": "Delta Sync Seed Note",
                "raw_text": "Content for delta sync test",
                "captured_at": datetime.now(UTC).isoformat(),
            },
            headers=headers,
        )

        resp = await ac.get("/api/v1/sync/delta?since_version=0", headers=headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["since_version"] == 0
        assert data["current_max_sync_version"] >= 1
        assert "captures" in data
        assert isinstance(data["captures"], list)
        assert len(data["captures"]) >= 1
