from __future__ import annotations

import hashlib
import tempfile
import uuid
from datetime import UTC, datetime
from pathlib import Path
from unittest.mock import patch

import fitz  # PyMuPDF
import numpy as np
import pytest
from httpx import ASGITransport, AsyncClient
from PIL import Image
from sqlmodel import col, select

from app.core.config import settings
from app.db.session import AsyncSessionLocal
from app.main import app
from app.models.enums import CaptureTypeEnum, ProcessingStatusEnum
from app.models.tables import Capture, Device, Embedding, MediaAsset, ReadingSession
from app.services import scraper
from app.services.embedder import EmbeddingGemmaService
from app.workers import tasks
from app.workers.tasks import job_ingest_capture


class MockSentenceTransformer:
    def __init__(self) -> None:
        self.device = "cpu"

    def encode(
        self,
        sentences: list[str] | str,
        normalize_embeddings: bool = True,
        show_progress_bar: bool = False,
        prompt_name: str | None = None,
    ) -> np.ndarray:
        if isinstance(sentences, str):
            vec = np.random.randn(768).astype(np.float32)
            if normalize_embeddings:
                norm = float(np.linalg.norm(vec))
                vec = vec / max(norm, 1e-12)
            return vec
        n = len(sentences)
        vecs = np.random.randn(n, 768).astype(np.float32)
        if normalize_embeddings:
            norms = np.linalg.norm(vecs, axis=1, keepdims=True)
            vecs = vecs / np.maximum(norms, 1e-12)
        return vecs


@pytest.fixture(autouse=True)
def setup_mock_embedder():
    mock_model = MockSentenceTransformer()
    test_embedder = EmbeddingGemmaService(device="cpu", model=mock_model)
    tasks.set_embedder(test_embedder)
    yield
    tasks.set_embedder(None)


@pytest.mark.asyncio
async def test_01_pdf_document_ingestion():
    """Ingesting a pdf_document extracts native text, renders page images with soft_token_budget=1120, and sets INDEXED."""
    # 1. Create a 2-page test PDF with PyMuPDF
    doc = fitz.open()
    page1 = doc.new_page()
    page1.insert_text(
        (50, 50),
        "Dense test document introduction. This page has enough text layout to trigger high-resolution rendering. "
        * 10,
    )
    page1.draw_rect(fitz.Rect(50, 50, 200, 200), color=(1, 0, 0))
    page2 = doc.new_page()
    page2.insert_text((50, 50), "Page two content with details and system architecture diagrams.")

    with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as f:
        pdf_temp_path = Path(f.name)
    doc.save(str(pdf_temp_path))
    doc.close()

    cap_id = uuid.uuid4()
    device_id = uuid.uuid4()

    async with AsyncSessionLocal() as session:
        # Create device
        dev = Device(
            id=device_id,
            device_name=f"PDF-Worker-Test-{uuid.uuid4().hex[:6]}",
            device_type="linux",
            api_key_hash=hashlib.sha256(uuid.uuid4().bytes).hexdigest(),
        )
        session.add(dev)
        await session.flush()

        capture = Capture(
            id=cap_id,
            device_id=device_id,
            capture_type=CaptureTypeEnum.pdf_document,
            processing_status=ProcessingStatusEnum.QUEUED,
            title="Distributed Consensus Whitepaper",
            captured_at=datetime.now(UTC),
        )
        session.add(capture)

        media = MediaAsset(
            id=uuid.uuid4(),
            capture_id=cap_id,
            media_kind="pdf",
            local_rel_path=str(pdf_temp_path),
            mime_type="application/pdf",
            file_size_bytes=pdf_temp_path.stat().st_size,
            sha256_checksum=hashlib.sha256(pdf_temp_path.read_bytes()).hexdigest(),
            page_order=1,
            soft_token_budget=1120,
        )
        session.add(media)
        await session.commit()

    # 2. Run background ingestion job
    await job_ingest_capture(str(cap_id))

    # 3. Assertions
    async with AsyncSessionLocal() as session:
        updated_cap = await session.get(Capture, cap_id)
        assert updated_cap is not None
        assert updated_cap.processing_status == ProcessingStatusEnum.INDEXED
        assert updated_cap.extracted_markdown is not None
        assert "Dense test document introduction" in updated_cap.extracted_markdown
        assert "Page two content" in updated_cap.extracted_markdown

        # Verify rendered images exist in media_assets with 1120 soft token budget
        assets_res = await session.execute(
            select(MediaAsset).where(
                col(MediaAsset.capture_id) == cap_id,
                col(MediaAsset.mime_type) == "image/jpeg",
            )
        )
        rendered_assets = assets_res.scalars().all()
        assert len(rendered_assets) >= 1
        for a in rendered_assets:
            assert a.soft_token_budget == 1120

        # Verify embeddings were generated
        emb_res = await session.execute(
            select(Embedding).where(col(Embedding.owner_id) == cap_id)
        )
        embeddings = emb_res.scalars().all()
        assert len(embeddings) >= 1
        for emb in embeddings:
            assert len(emb.embedding) == 768

    pdf_temp_path.unlink(missing_ok=True)


@pytest.mark.asyncio
async def test_02_book_scan_reading_session_inheritance():
    """Ingesting a book_scan linked to an active ReadingSession inherits source_title and default_tags."""
    session_id = uuid.uuid4()
    cap_id = uuid.uuid4()
    device_id = uuid.uuid4()

    # Create dummy image for OCR
    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as f:
        img_temp_path = Path(f.name)
    im = Image.new("RGB", (200, 100), color=(255, 255, 255))
    im.save(str(img_temp_path))

    async with AsyncSessionLocal() as session:
        dev = Device(
            id=device_id,
            device_name=f"Book-Worker-Test-{uuid.uuid4().hex[:6]}",
            device_type="android",
            api_key_hash=hashlib.sha256(uuid.uuid4().bytes).hexdigest(),
        )
        session.add(dev)
        await session.flush()

        rs = ReadingSession(
            id=session_id,
            device_id=device_id,
            source_title="Designing Data-Intensive Applications",
            author="Martin Kleppmann",
            default_tags=["distributed-systems", "databases"],
            is_active=True,
        )
        session.add(rs)
        await session.flush()

        cap = Capture(
            id=cap_id,
            device_id=device_id,
            reading_session_id=session_id,
            capture_type=CaptureTypeEnum.book_scan,
            processing_status=ProcessingStatusEnum.QUEUED,
            page_range="pp. 45-48",
            user_tags=["storage-engines"],
            captured_at=datetime.now(UTC),
        )
        session.add(cap)

        media = MediaAsset(
            id=uuid.uuid4(),
            capture_id=cap_id,
            media_kind="image",
            local_rel_path=str(img_temp_path),
            mime_type="image/jpeg",
            file_size_bytes=img_temp_path.stat().st_size,
            sha256_checksum=hashlib.sha256(img_temp_path.read_bytes()).hexdigest(),
            page_order=1,
            soft_token_budget=1120,
        )
        session.add(media)
        await session.commit()

    # Run ingestion
    await job_ingest_capture(str(cap_id))

    async with AsyncSessionLocal() as session:
        updated_cap = await session.get(Capture, cap_id)
        assert updated_cap is not None
        assert updated_cap.processing_status == ProcessingStatusEnum.INDEXED
        assert updated_cap.extracted_title is not None
        assert "Designing Data-Intensive Applications" in updated_cap.extracted_title
        assert "Martin Kleppmann" in updated_cap.extracted_title
        assert "pp. 45-48" in updated_cap.extracted_title

        # Check tag merge
        tags = set(updated_cap.user_tags or [])
        assert "storage-engines" in tags
        assert "distributed-systems" in tags
        assert "databases" in tags

    img_temp_path.unlink(missing_ok=True)


@pytest.mark.asyncio
async def test_03_blocked_video_reel_fallback():
    """Simulating a blocked Instagram Reel sets EXTRACTION_PARTIAL and still embeds fallback text."""
    cap_id = uuid.uuid4()
    device_id = uuid.uuid4()

    async with AsyncSessionLocal() as session:
        dev = Device(
            id=device_id,
            device_name=f"Reel-Worker-Test-{uuid.uuid4().hex[:6]}",
            device_type="web",
            api_key_hash=hashlib.sha256(uuid.uuid4().bytes).hexdigest(),
        )
        session.add(dev)
        await session.flush()

        cap = Capture(
            id=cap_id,
            device_id=device_id,
            capture_type=CaptureTypeEnum.video_reel,
            source_url="https://www.instagram.com/reel/Cxyz12345",
            raw_text="Check out this cool Raft cluster demo",
            processing_status=ProcessingStatusEnum.QUEUED,
            captured_at=datetime.now(UTC),
        )
        session.add(cap)
        await session.commit()

    # Mock extract_video_reel to raise PartialExtractionError
    async def mock_blocked(*args, **kwargs):
        raise scraper.PartialExtractionError(
            og_title="Viral Reel: Raft Consensus in Go",
            og_description="Visual walkthrough of leader election and log replication.",
        )

    with patch.object(scraper, "extract_video_reel", side_effect=mock_blocked):
        await job_ingest_capture(str(cap_id))

    async with AsyncSessionLocal() as session:
        updated_cap = await session.get(Capture, cap_id)
        assert updated_cap is not None
        assert updated_cap.processing_status == ProcessingStatusEnum.EXTRACTION_PARTIAL
        assert updated_cap.extracted_title == "Viral Reel: Raft Consensus in Go"
        assert updated_cap.extraction_metadata is not None
        assert "Raft Consensus" in str(updated_cap.extraction_metadata)

        # Fallback embeddings must still exist!
        emb_res = await session.execute(
            select(Embedding).where(col(Embedding.owner_id) == cap_id)
        )
        embeddings = emb_res.scalars().all()
        assert len(embeddings) >= 1
        assert len(embeddings[0].embedding) == 768


@pytest.mark.asyncio
async def test_04_partial_captures_list_and_rescue():
    """GET /api/v1/captures/partial lists blocked captures, and POST /rescue upgrades capture to INDEXED."""
    raw_token = f"mem_live_{uuid.uuid4().hex}{uuid.uuid4().hex}"
    token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
    cap_id = uuid.uuid4()
    device_id = uuid.uuid4()

    async with AsyncSessionLocal() as session:
        dev = Device(
            id=device_id,
            device_name=f"Rescue-Worker-Test-{uuid.uuid4().hex[:6]}",
            device_type="web",
            api_key_hash=token_hash,
        )
        session.add(dev)
        await session.flush()

        cap = Capture(
            id=cap_id,
            device_id=device_id,
            capture_type=CaptureTypeEnum.video_reel,
            source_url="https://www.instagram.com/reel/BlockedReel",
            raw_text="Blocked Reel Note",
            processing_status=ProcessingStatusEnum.EXTRACTION_PARTIAL,
            captured_at=datetime.now(UTC),
        )
        session.add(cap)
        await session.commit()

    headers = {
        "CF-Access-Client-Id": settings.CF_ACCESS_CLIENT_ID,
        "CF-Access-Client-Secret": settings.CF_ACCESS_CLIENT_SECRET,
        "Authorization": f"Bearer {raw_token}",
    }

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        # 1. Check partial list
        list_resp = await client.get("/api/v1/captures/partial", headers=headers)
        assert list_resp.status_code == 200
        partial_items = list_resp.json()
        assert any(item["id"] == str(cap_id) for item in partial_items)

        # 2. Call rescue endpoint
        rescue_payload = {
            "dom_fallback_markdown": "# Rescued DOM Content\n\nRecovered full reel transcript and captions from extension.",
            "title": "Rescued Reel Title",
        }
        rescue_resp = await client.post(
            f"/api/v1/captures/{cap_id}/rescue",
            headers=headers,
            json=rescue_payload,
        )
        assert rescue_resp.status_code == 202
        assert rescue_resp.json()["status"] == "accepted"

    # Ingest rescued capture
    await job_ingest_capture(str(cap_id))

    async with AsyncSessionLocal() as session:
        rescued_cap = await session.get(Capture, cap_id)
        assert rescued_cap is not None
        assert rescued_cap.processing_status == ProcessingStatusEnum.INDEXED
        assert rescued_cap.extracted_title == "Rescued Reel Title"
        assert "Rescued DOM Content" in (rescued_cap.extracted_markdown or "")


def test_05_youtube_timestamp_and_clip_range():
    """Timestamp parser parses long YouTube URLs and compute_clip_range computes exact ±30s window."""
    urls = [
        ("https://www.youtube.com/watch?v=abc12345&t=142s", 142),
        ("https://www.youtube.com/watch?v=abc12345?t=2m15s", 135),
        ("https://youtu.be/abc12345?t=1h2m3s", 3723),
        ("https://youtu.be/abc12345&t=142", 142),
        ("https://www.youtube.com/watch?v=abc12345#t=45s", 45),
    ]

    for url, expected_sec in urls:
        parsed = scraper.parse_youtube_timestamp(url)
        assert parsed == expected_sec, f"Failed for {url}: got {parsed}, expected {expected_sec}"

    # For t=142s, clip range ±30s must be [112, 172]
    start_s, end_s = scraper.compute_clip_range(142, 30)
    assert start_s == 112
    assert end_s == 172

    # For t=15s (boundary condition), start must not be negative
    start_early, end_early = scraper.compute_clip_range(15, 30)
    assert start_early == 0
    assert end_early == 45
