import hashlib
from datetime import UTC, datetime

from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col, select

from app.core.config import settings
from app.db.session import get_async_session
from app.models.tables import Device

security_bearer = HTTPBearer(auto_error=False)


async def get_current_device(
    credentials: HTTPAuthorizationCredentials | None = Depends(security_bearer),
    cf_client_id: str | None = Header(None, alias="CF-Access-Client-Id"),
    cf_client_secret: str | None = Header(None, alias="CF-Access-Client-Secret"),
    session: AsyncSession = Depends(get_async_session),
) -> Device:
    """Zero-Trust authentication verifying CF Access headers and Bearer API key."""
    # 1. Enforce Cloudflare Access headers if configured
    if settings.ENFORCE_CF_HEADERS:
        if not cf_client_id or not cf_client_secret:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing Cloudflare Zero Trust Access headers",
            )
        if (settings.CF_ACCESS_CLIENT_ID and cf_client_id != settings.CF_ACCESS_CLIENT_ID) or (
            settings.CF_ACCESS_CLIENT_SECRET
            and cf_client_secret != settings.CF_ACCESS_CLIENT_SECRET
        ):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Cloudflare Zero Trust Access Service Token",
            )

    # 2. Extract Bearer token
    if not credentials or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Bearer token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    raw_token = credentials.credentials
    token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()

    # 3. Query active device by api_key_hash
    stmt = select(Device).where(
        col(Device.api_key_hash) == token_hash,
        col(Device.is_revoked).is_(False),
    )
    result = await session.execute(stmt)
    device = result.scalar_one_or_none()

    if not device:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or revoked device token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # 4. Asynchronously update device.last_sync_at
    device.last_sync_at = datetime.now(UTC)
    session.add(device)
    await session.commit()
    await session.refresh(device)

    return device
