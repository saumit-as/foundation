from __future__ import annotations

import hashlib
import secrets
from typing import Any, Literal
from uuid import UUID

import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col, func, select

from app.core.config import settings
from app.db.session import get_async_session
from app.models.enums import ProcessingStatusEnum
from app.models.tables import AiSpark, Capture, Device, PersonaSnapshot

router = APIRouter(prefix="/system", tags=["System & Dashboard"])


class RegisterDeviceRequest(BaseModel):
    device_name: str = Field(..., min_length=1, max_length=128)
    device_type: Literal["android", "linux", "windows", "browser_ext"]


class DeviceResponse(BaseModel):
    id: UUID
    device_name: str
    device_type: str
    created_at: str
    last_sync_at: str | None
    is_revoked: bool


@router.get("/status")
async def get_system_status(
    session: AsyncSession = Depends(get_async_session),
) -> dict[str, Any]:
    # 1. Database check
    db_ok = False
    try:
        res = await session.execute(select(func.count(col(Device.id))))
        device_count = res.scalar() or 0
        db_ok = True
    except Exception:
        device_count = 0

    # 2. Redis check
    redis_ok = False
    try:
        import redis.asyncio as aioredis
        r = aioredis.from_url(settings.REDIS_URL, decode_responses=True)
        redis_ok = await r.ping()
        await r.aclose()
    except Exception:
        pass

    # 3. ntfy check
    ntfy_ok = False
    try:
        async with httpx.AsyncClient(timeout=2.0) as client:
            resp = await client.get(f"{settings.NTFY_INTERNAL_URL}/v1/health")
            ntfy_ok = resp.status_code == 200
    except Exception:
        pass

    # 4. Captures breakdown
    capture_counts: dict[str, int] = {}
    try:
        for status_enum in ProcessingStatusEnum:
            cnt_stmt = select(func.count(col(Capture.id))).where(
                col(Capture.processing_status) == status_enum,
                col(Capture.is_deleted).is_(False),
            )
            cnt = (await session.execute(cnt_stmt)).scalar() or 0
            capture_counts[status_enum.value] = cnt
    except Exception:
        pass

    # 5. Sparks count
    spark_count = 0
    try:
        spark_res = await session.execute(select(func.count(col(AiSpark.id))))
        spark_count = spark_res.scalar() or 0
    except Exception:
        pass

    # 6. Current Persona
    persona_ver = 0
    persona_summary = "Not seeded"
    try:
        p_stmt = select(PersonaSnapshot).where(col(PersonaSnapshot.is_current).is_(True))
        p_snap = (await session.execute(p_stmt)).scalars().first()
        if p_snap:
            persona_ver = p_snap.version_number
            persona_summary = p_snap.summary_diff or "Current active baseline persona"
    except Exception:
        pass

    # 7. Devices list
    devices_list: list[dict[str, Any]] = []
    try:
        dev_stmt = select(Device).order_by(col(Device.created_at).desc())
        devs = (await session.execute(dev_stmt)).scalars().all()
        devices_list = [
            {
                "id": str(d.id),
                "device_name": d.device_name,
                "device_type": d.device_type,
                "created_at": d.created_at.isoformat(),
                "last_sync_at": d.last_sync_at.isoformat() if d.last_sync_at else None,
                "is_revoked": d.is_revoked,
            }
            for d in devs
        ]
    except Exception:
        pass

    return {
        "services": {
            "postgres": {"status": "healthy" if db_ok else "unreachable", "ok": db_ok},
            "redis": {"status": "healthy" if redis_ok else "unreachable", "ok": redis_ok},
            "ntfy": {"status": "healthy" if ntfy_ok else "unreachable", "ok": ntfy_ok},
            "embedder": {
                "model_id": settings.EMBEDDING_MODEL_ID,
                "device": settings.EMBEDDING_DEVICE,
                "dimensions": 768,
                "precision": "float32/bfloat16",
            },
            "llm": {
                "model_id": settings.OPENAI_MODEL_ID,
                "configured": bool(settings.OPENAI_API_KEY),
            },
        },
        "stats": {
            "total_captures": sum(capture_counts.values()),
            "captures_by_status": capture_counts,
            "total_sparks": spark_count,
            "total_devices": device_count,
            "persona_version": persona_ver,
            "persona_summary": persona_summary,
        },
        "devices": devices_list,
    }


@router.post("/register-device")
async def register_new_device(
    payload: RegisterDeviceRequest,
    session: AsyncSession = Depends(get_async_session),
) -> dict[str, Any]:
    raw_token = f"mem_live_{secrets.token_hex(32)}"
    api_key_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()

    device = Device(
        device_name=payload.device_name,
        device_type=payload.device_type,
        api_key_hash=api_key_hash,
    )
    session.add(device)
    await session.commit()
    await session.refresh(device)

    return {
        "v": 1,
        "api_base_url": settings.PUBLIC_API_BASE_URL,
        "cf_access_client_id": settings.CF_ACCESS_CLIENT_ID or "",
        "cf_access_client_secret": settings.CF_ACCESS_CLIENT_SECRET or "",
        "device_id": str(device.id),
        "device_name": device.device_name,
        "device_type": device.device_type,
        "bearer_key": raw_token,
        "ntfy_url": settings.NTFY_PUBLIC_URL,
        "ntfy_topic": settings.NTFY_TOPIC,
        "ntfy_token": settings.NTFY_ACCESS_TOKEN or "",
    }


@router.post("/devices/{device_id}/revoke")
async def revoke_device(
    device_id: UUID,
    session: AsyncSession = Depends(get_async_session),
) -> dict[str, str]:
    device = await session.get(Device, device_id)
    if not device:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Device not found")

    device.is_revoked = True
    session.add(device)
    await session.commit()

    return {"status": "ok", "message": f"Device {device.device_name} revoked"}
