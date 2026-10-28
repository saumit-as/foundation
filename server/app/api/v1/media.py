import hashlib
import os
import re
import uuid
from datetime import UTC, datetime

from fastapi import (
    APIRouter,
    Depends,
    Form,
    Header,
    HTTPException,
    Request,
    Response,
    UploadFile,
    status,
)
from fastapi.responses import FileResponse, StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col, select

from app.core.config import settings
from app.core.security import get_current_device
from app.db.session import get_async_session
from app.models.tables import Capture, Device, MediaAsset
from app.schemas.capture import MediaUploadResponse

router = APIRouter()


@router.post(
    "/capture/{capture_id}/media",
    response_model=MediaUploadResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Binary Multipart Upload for Media Assets",
)
async def upload_capture_media(
    capture_id: uuid.UUID,
    file: UploadFile,
    media_kind: str = Form(...),
    sha256_checksum: str = Form(...),
    page_order: int = Form(0),
    soft_token_budget: int = Form(280),
    duration_seconds: float | None = Form(None),
    width_px: int | None = Form(None),
    height_px: int | None = Form(None),
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> MediaUploadResponse:
    # 1. Verify capture exists
    cap_res = await session.execute(select(Capture).where(col(Capture.id) == capture_id))
    capture = cap_res.scalar_one_or_none()
    if not capture:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Parent capture {capture_id} not found",
        )

    # 2. Determine file storage path
    asset_id = uuid.uuid4()
    now = datetime.now(UTC)
    year, month = now.strftime("%Y"), now.strftime("%m")
    extension = os.path.splitext(file.filename or "")[1] or ".bin"
    rel_path = f"{year}/{month}/{capture_id}/{asset_id}{extension}"
    full_path = settings.MEDIA_ROOT / rel_path
    full_path.parent.mkdir(parents=True, exist_ok=True)

    # 3. Stream to disk while computing SHA-256
    sha256 = hashlib.sha256()
    bytes_written = 0

    with open(full_path, "wb") as f:
        while chunk := await file.read(64 * 1024):
            sha256.update(chunk)
            f.write(chunk)
            bytes_written += len(chunk)

    computed_hash = sha256.hexdigest().lower()
    expected_hash = sha256_checksum.strip().lower()

    if computed_hash != expected_hash:
        # Delete corrupt/incomplete file
        if full_path.exists():
            full_path.unlink()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"SHA-256 checksum mismatch: expected {expected_hash}, calculated {computed_hash}",
        )

    # 4. Insert MediaAsset record
    mime_type = file.content_type or "application/octet-stream"
    media_asset = MediaAsset(
        id=asset_id,
        capture_id=capture_id,
        media_kind=media_kind,
        page_order=page_order,
        local_rel_path=rel_path,
        mime_type=mime_type,
        file_size_bytes=bytes_written,
        sha256_checksum=computed_hash,
        duration_seconds=duration_seconds,
        width_px=width_px,
        height_px=height_px,
        soft_token_budget=soft_token_budget,
    )
    session.add(media_asset)
    await session.commit()

    return MediaUploadResponse(
        status="CREATED",
        asset_id=media_asset.id,
        capture_id=capture_id,
        local_rel_path=rel_path,
        file_size_bytes=bytes_written,
        sha256_checksum=computed_hash,
        mime_type=mime_type,
    )


@router.get(
    "/media/{asset_id}",
    summary="Authenticated Media Streaming & Thumbnail Fetch (Range-enabled)",
)
async def stream_media_asset(
    asset_id: uuid.UUID,
    request: Request,
    range_header: str | None = Header(None, alias="Range"),
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> Response:
    res = await session.execute(select(MediaAsset).where(col(MediaAsset.id) == asset_id))
    asset = res.scalar_one_or_none()
    if not asset:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Media asset not found")

    full_path = settings.MEDIA_ROOT / asset.local_rel_path
    if not full_path.exists():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Media file missing from disk"
        )

    file_size = asset.file_size_bytes
    etag = f'"{asset.sha256_checksum}"'

    # Support HTTP 206 Partial Content Range streaming
    if range_header:
        range_match = re.match(r"bytes=(\d+)-(\d*)", range_header)
        if range_match:
            start = int(range_match.group(1))
            end_str = range_match.group(2)
            end = int(end_str) if end_str else file_size - 1

            if start >= file_size or end >= file_size or start > end:
                raise HTTPException(
                    status_code=status.HTTP_416_REQUESTED_RANGE_NOT_SATISFIABLE,
                    headers={"Content-Range": f"bytes */{file_size}"},
                )

            chunk_length = end - start + 1

            def iter_file_chunk():
                with open(full_path, "rb") as f:
                    f.seek(start)
                    remaining = chunk_length
                    while remaining > 0:
                        read_size = min(64 * 1024, remaining)
                        data = f.read(read_size)
                        if not data:
                            break
                        remaining -= len(data)
                        yield data

            headers = {
                "Content-Range": f"bytes {start}-{end}/{file_size}",
                "Accept-Ranges": "bytes",
                "Content-Length": str(chunk_length),
                "Content-Type": asset.mime_type,
                "ETag": etag,
                "Cache-Control": "private, max-age=31536000, immutable",
            }
            return StreamingResponse(
                iter_file_chunk(),
                status_code=status.HTTP_206_PARTIAL_CONTENT,
                headers=headers,
            )

    headers = {
        "Accept-Ranges": "bytes",
        "ETag": etag,
        "Cache-Control": "private, max-age=31536000, immutable",
    }
    return FileResponse(
        path=str(full_path),
        media_type=asset.mime_type,
        headers=headers,
    )
