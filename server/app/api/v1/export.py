from __future__ import annotations

import io
import logging
import zipfile
from typing import Any

from fastapi import APIRouter, Depends, Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col, select

from app.core.security import get_current_device
from app.db.session import get_async_session
from app.models.tables import AISpark, Capture, Device, DocumentLink
from app.services.exporter import export_spark_to_markdown

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Vault Export"])


@router.get("/export/vault")
async def export_vault_archive(
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
) -> Response:
    """Exports entire scratchpad and spark collection into an Obsidian-ready ZIP vault."""
    zip_buffer = io.BytesIO()

    # Load all active captures
    cap_stmt = select(Capture).where(col(Capture.is_deleted).is_(False))
    cap_res = await session.execute(cap_stmt)
    captures = list(cap_res.scalars().all())
    cap_map = {c.id: c for c in captures}

    # Load all active sparks
    spark_stmt = select(AISpark).where(col(AISpark.is_dismissed).is_(False))
    spark_res = await session.execute(spark_stmt)
    sparks = list(spark_res.scalars().all())

    # Load links
    link_stmt = select(DocumentLink).where(col(DocumentLink.target_table) == "captures")
    link_res = await session.execute(link_stmt)
    links = list(link_res.scalars().all())
    links_by_spark: dict[Any, list[Capture]] = {}
    for lnk in links:
        if lnk.source_id not in links_by_spark:
            links_by_spark[lnk.source_id] = []
        if lnk.target_id in cap_map:
            links_by_spark[lnk.source_id].append(cap_map[lnk.target_id])

    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
        # Write Captures
        for c in captures:
            clean_title = (c.title or c.extracted_title or f"Capture_{c.id}").replace("/", "-")
            filename = f"captures/{clean_title[:80]}_{str(c.id)[:8]}.md"
            content = f"# {clean_title}\n\nCaptured: {c.captured_at}\nType: {c.capture_type}\nTags: {c.user_tags}\n\n## Note\n{c.raw_text or ''}\n\n## Annotations\n{c.annotations_concat or ''}\n"
            zf.writestr(filename, content)

        # Write Sparks
        for s in sparks:
            clean_title = s.title.replace("/", "-")
            filename = f"sparks/{clean_title[:80]}_{str(s.id)[:8]}.md"
            parents = links_by_spark.get(s.id, [])
            md_content = export_spark_to_markdown(s, parents)
            zf.writestr(filename, md_content)

    zip_bytes = zip_buffer.getvalue()
    return Response(
        content=zip_bytes,
        media_type="application/zip",
        headers={"Content-Disposition": 'attachment; filename="memoria_obsidian_vault.zip"'},
    )
