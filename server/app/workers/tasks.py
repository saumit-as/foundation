from __future__ import annotations

import contextlib
import hashlib
import logging
import traceback
from pathlib import Path
from uuid import UUID, uuid4

from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlmodel import col, select
from taskiq_redis import ListQueueBroker

from app.core.config import settings
from app.db.session import AsyncSessionLocal
from app.models.enums import CaptureTypeEnum, ProcessingStatusEnum
from app.models.tables import Capture, Embedding, MediaAsset, ReadingSession
from app.services import scraper
from app.services.embedder import EmbeddingGemmaService

logger = logging.getLogger(__name__)

broker = ListQueueBroker(
    url=settings.REDIS_URL,
    queue_name="memoria_tasks",
)

# Global embedder instance (lazy loaded)
_embedder_instance: EmbeddingGemmaService | None = None


def get_embedder() -> EmbeddingGemmaService:
    global _embedder_instance
    if _embedder_instance is None:
        _embedder_instance = EmbeddingGemmaService(device=settings.EMBEDDING_DEVICE)
    return _embedder_instance


def set_embedder(embedder: EmbeddingGemmaService | None) -> None:
    global _embedder_instance
    _embedder_instance = embedder


@broker.task
async def job_evaluate_spark_and_reminders(capture_id_str: str) -> None:
    """Downstream hook for gpt-6-luna sparks and reminders (implemented in Task 06/07)."""
    logger.info("Evaluating sparks and reminders for capture %s", capture_id_str)


@broker.task
async def job_ingest_capture(capture_id_str: str, retry_count: int = 0) -> None:
    """Asynchronous background ingestion pipeline for captures."""
    capture_id = UUID(capture_id_str)
    logger.info("Starting ingestion for capture %s (attempt %d)", capture_id, retry_count + 1)

    async with AsyncSessionLocal() as session:
        capture = await session.get(Capture, capture_id)
        if not capture or capture.is_deleted:
            logger.warning("Capture %s not found or deleted", capture_id)
            return

        # 1. Transition to EXTRACTING_MEDIA
        capture.processing_status = ProcessingStatusEnum.EXTRACTING_MEDIA
        await session.commit()
        await session.refresh(capture)

        # 2. Reading Session inheritance
        if capture.reading_session_id:
            reading_session = await session.get(ReadingSession, capture.reading_session_id)
            if reading_session:
                prefix_parts = [reading_session.source_title]
                if reading_session.author:
                    prefix_parts.append(f"({reading_session.author})")
                if capture.page_range:
                    prefix_parts.append(f"- {capture.page_range}")
                inherited_prefix = " ".join(prefix_parts).strip()

                current_title = capture.extracted_title or capture.title or ""
                capture.extracted_title = (
                    f"{inherited_prefix}: {current_title}" if current_title else inherited_prefix
                )

                if reading_session.default_tags:
                    existing_tags = set(capture.user_tags or [])
                    existing_tags.update(reading_session.default_tags)
                    capture.user_tags = list(existing_tags)
                await session.commit()

        is_partial = False
        partial_title: str | None = None
        partial_desc: str | None = None

        try:
            # 3. Modality-Specific Media Extraction
            if capture.capture_type == CaptureTypeEnum.article_url and capture.source_url:
                title, md = scraper.extract_article(
                    capture.source_url, capture.extracted_markdown
                )
                if not capture.title:
                    capture.extracted_title = title
                capture.extracted_markdown = md

            elif capture.capture_type == CaptureTypeEnum.pdf_document:
                # Find PDF media asset
                media_stmt = select(MediaAsset).where(
                    col(MediaAsset.capture_id) == capture_id,
                    col(MediaAsset.mime_type) == "application/pdf",
                )
                media_res = await session.execute(media_stmt)
                pdf_asset = media_res.scalars().first()
                if pdf_asset and pdf_asset.local_rel_path:
                    pdf_path = Path(pdf_asset.local_rel_path)
                    if pdf_path.exists():
                        pdf_title, pdf_md, rendered_pages = scraper.extract_pdf(
                            pdf_path, capture_id
                        )
                        if not capture.title:
                            capture.extracted_title = pdf_title
                        capture.extracted_markdown = pdf_md

                        # Insert rendered pages into media_assets
                        for p in rendered_pages:
                            file_bytes = Path(p["file_path"]).read_bytes()
                            checksum = hashlib.sha256(file_bytes).hexdigest()
                            new_asset = MediaAsset(
                                id=uuid4(),
                                capture_id=capture_id,
                                media_kind="image",
                                local_rel_path=p["file_path"],
                                mime_type=p["mime_type"],
                                file_size_bytes=len(file_bytes),
                                sha256_checksum=checksum,
                                page_order=p["page_order"],
                                soft_token_budget=p["soft_token_budget"],
                            )
                            session.add(new_asset)

            elif capture.capture_type == CaptureTypeEnum.video_reel and capture.source_url:
                if capture.extracted_markdown:
                    # Capture was rescued via browser DOM fallback
                    pass
                else:
                    try:
                        res = await scraper.extract_video_reel(capture.source_url, capture_id)
                        if not capture.title:
                            capture.extracted_title = res.get("title")
                        if res.get("transcript"):
                            capture.transcript_text = res["transcript"]
                    except scraper.PartialExtractionError as pe:
                        is_partial = True
                        partial_title = pe.og_title
                        partial_desc = pe.og_description
                        capture.processing_status = ProcessingStatusEnum.EXTRACTION_PARTIAL
                        if partial_title and not capture.title:
                            capture.extracted_title = partial_title
                        meta = capture.extraction_metadata or {}
                        meta["og_title"] = partial_title
                        meta["og_description"] = partial_desc
                        capture.extraction_metadata = meta

            elif capture.capture_type in (
                CaptureTypeEnum.book_scan,
                CaptureTypeEnum.image_upload,
            ):
                media_stmt = (
                    select(MediaAsset)
                    .where(col(MediaAsset.capture_id) == capture_id)
                    .order_by(col(MediaAsset.page_order).asc())
                )
                media_res = await session.execute(media_stmt)
                assets = media_res.scalars().all()
                image_paths = [
                    Path(a.local_rel_path) for a in assets if Path(a.local_rel_path).exists()
                ]

                if image_paths:
                    is_book = capture.capture_type == CaptureTypeEnum.book_scan
                    ocr_res, page_meta = scraper.extract_image_or_book_ocr(
                        image_paths, is_book_scan=is_book
                    )
                    capture.ocr_text = ocr_res

                    # Update soft_token_budgets
                    meta_map = {m["file_path"]: m["soft_token_budget"] for m in page_meta}
                    for a in assets:
                        if a.local_rel_path in meta_map:
                            a.soft_token_budget = meta_map[a.local_rel_path]
                            session.add(a)

            elif capture.capture_type == CaptureTypeEnum.audio_memo:
                media_stmt = select(MediaAsset).where(col(MediaAsset.capture_id) == capture_id)
                media_res = await session.execute(media_stmt)
                audio_asset = media_res.scalars().first()
                if audio_asset and Path(audio_asset.local_rel_path).exists():
                    transcript = scraper.transcribe_audio(Path(audio_asset.local_rel_path))
                    capture.transcript_text = transcript

            # Transition to EMBEDDING if not partial
            if not is_partial:
                capture.processing_status = ProcessingStatusEnum.EMBEDDING
            await session.commit()
            await session.refresh(capture)

            # 4. Generate & Save Embeddings
            embedder = get_embedder()
            active_title = capture.title or capture.extracted_title or "Untitled Note"

            body_text = (
                capture.extracted_markdown
                or capture.ocr_text
                or capture.transcript_text
                or capture.raw_text
                or ""
            )

            # In partial mode, append OG metadata
            if is_partial and partial_desc:
                body_text = f"{body_text}\n{partial_desc}".strip()

            chunks = await embedder.chunk_and_encode_long_text(active_title, body_text)
            for chunk_idx, preview, vector in chunks:
                upsert_stmt = (
                    pg_insert(Embedding)
                    .values(
                        id=uuid4(),
                        owner_id=capture_id,
                        owner_table="captures",
                        chunk_index=chunk_idx,
                        modality_composition="text",
                        chunk_preview_text=preview,
                        token_count=len(preview.split()),
                        embedding=vector,
                    )
                    .on_conflict_do_update(
                        index_elements=["owner_id", "owner_table", "chunk_index"],
                        set_={
                            "chunk_preview_text": preview,
                            "token_count": len(preview.split()),
                            "embedding": vector,
                        },
                    )
                )
                await session.execute(upsert_stmt)

            # 5. Transition to INDEXED (or preserve EXTRACTION_PARTIAL)
            if not is_partial:
                capture.processing_status = ProcessingStatusEnum.INDEXED
            await session.commit()

            # Enqueue spark & reminder evaluation
            with contextlib.suppress(Exception):
                await job_evaluate_spark_and_reminders.kiq(str(capture_id))

        except Exception as exc:
            logger.error("Error processing capture %s: %s", capture_id, exc)
            if retry_count < 2:  # Retry up to 3 times total
                capture.processing_status = ProcessingStatusEnum.FAILED_RETRYABLE
                meta = capture.extraction_metadata or {}
                meta["last_retry_error"] = str(exc)
                meta["retry_count"] = retry_count + 1
                capture.extraction_metadata = meta
                await session.commit()
                # Schedule retry
                with contextlib.suppress(Exception):
                    await job_ingest_capture.kiq(str(capture_id), retry_count=retry_count + 1)
                return

            # Permanent failure fallback -> DEAD_LETTER
            logger.warning(
                "Permanent failure for capture %s; falling back to text indexing", capture_id
            )
            capture.processing_status = ProcessingStatusEnum.DEAD_LETTER
            meta = capture.extraction_metadata or {}
            meta["error_log"] = traceback.format_exc()
            capture.extraction_metadata = meta

            # Always index at least title + raw_text + source_url
            try:
                embedder = get_embedder()
                fallback_title = capture.title or "Untitled"
                fallback_body = f"{capture.raw_text or ''} {capture.source_url or ''}".strip()
                chunks = await embedder.chunk_and_encode_long_text(fallback_title, fallback_body)
                for chunk_idx, preview, vector in chunks:
                    upsert_stmt = (
                        pg_insert(Embedding)
                        .values(
                            id=uuid4(),
                            owner_id=capture_id,
                            owner_table="captures",
                            chunk_index=chunk_idx,
                            modality_composition="text",
                            chunk_preview_text=preview,
                            token_count=len(preview.split()),
                            embedding=vector,
                        )
                        .on_conflict_do_update(
                            index_elements=["owner_id", "owner_table", "chunk_index"],
                            set_={
                                "chunk_preview_text": preview,
                                "token_count": len(preview.split()),
                                "embedding": vector,
                            },
                        )
                    )
                    await session.execute(upsert_stmt)
            except Exception as fe:
                logger.error("Failed fallback embedding for %s: %s", capture_id, fe)

            await session.commit()
