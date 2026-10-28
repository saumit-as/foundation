from __future__ import annotations

import hashlib
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import numpy as np
import pytest
from httpx import ASGITransport, AsyncClient
from sqlmodel import col, select, update

from app.core.config import settings
from app.db.session import AsyncSessionLocal
from app.main import app
from app.models.enums import CaptureTypeEnum, LinkTypeEnum, ProcessingStatusEnum
from app.models.tables import (
    AISpark,
    Capture,
    CaptureAnnotation,
    Device,
    DocumentLink,
    PersonaSnapshot,
)
from app.services.embedder import EmbeddingGemmaService
from app.services.luna_agent import (
    LunaAgentService,
    LunaCaptureEvaluation,
    ReminderDraft,
    SparkDocumentDraft,
    VoiceDistillationDraft,
    set_openai_client,
)
from app.workers import tasks
from app.workers.tasks import job_evaluate_spark_and_reminders


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
                vec = vec / max(float(np.linalg.norm(vec)), 1e-12)
            return vec
        n = len(sentences)
        vecs = np.random.randn(n, 768).astype(np.float32)
        if normalize_embeddings:
            norms = np.linalg.norm(vecs, axis=1, keepdims=True)
            vecs = vecs / np.maximum(norms, 1e-12)
        return vecs


@pytest.fixture(autouse=True)
def setup_test_embedder():
    mock_model = MockSentenceTransformer()
    test_embedder = EmbeddingGemmaService(device="cpu", model=mock_model)
    tasks.set_embedder(test_embedder)

    from app.api.v1 import search as search_module

    search_module._embedder_instance = test_embedder
    yield
    tasks.set_embedder(None)
    search_module._embedder_instance = None
    set_openai_client(None)


def test_01_prompt_prefix_byte_stability():
    """Calling _build_messages() across 3 different captures produces 100% byte-identical messages[0] with length >= 4096."""
    luna = LunaAgentService()
    base_prefix = "### BASE PERSONA CACHED SYSTEM INSTRUCTIONS\n" + ("PADDED CACHE LINE " * 100)

    cap1 = Capture(
        id=uuid.uuid4(),
        capture_type=CaptureTypeEnum.text_note,
        raw_text="Note 1 about distributed systems",
        title="DistSys 101",
        captured_at=datetime.now(UTC),
    )
    cap2 = Capture(
        id=uuid.uuid4(),
        capture_type=CaptureTypeEnum.video_reel,
        raw_text="Reel note about kubernetes ingress",
        title="K8s Ingress",
        captured_at=datetime.now(UTC),
    )
    cap3 = Capture(
        id=uuid.uuid4(),
        capture_type=CaptureTypeEnum.audio_memo,
        raw_text="Voice memo rambling thoughts on database sharding",
        title="DB Sharding Audio",
        captured_at=datetime.now(UTC),
    )

    msg1 = luna._build_messages(
        base_prefix, luna._build_scrubbed_capture_payload(cap1, [])
    )
    msg2 = luna._build_messages(
        base_prefix, luna._build_scrubbed_capture_payload(cap2, [])
    )
    msg3 = luna._build_messages(
        base_prefix, luna._build_scrubbed_capture_payload(cap3, [])
    )

    # 1. Message[0] role must be system
    assert msg1[0]["role"] == "system"
    assert msg2[0]["role"] == "system"
    assert msg3[0]["role"] == "system"

    # 2. Length must be >= 4096 chars (>= 1024 tokens)
    assert len(msg1[0]["content"]) >= 4096
    assert len(msg2[0]["content"]) >= 4096
    assert len(msg3[0]["content"]) >= 4096

    # 3. Exactly byte-identical prefix across all 3 different captures
    assert msg1[0]["content"] == msg2[0]["content"]
    assert msg2[0]["content"] == msg3[0]["content"]

    # 4. Message[1] must carry unique dynamic payload
    assert msg1[1]["content"] != msg2[1]["content"]
    assert msg2[1]["content"] != msg3[1]["content"]


@pytest.mark.asyncio
async def test_02_non_destructive_spark_and_audio_distillation():
    """job_evaluate_spark_and_reminders on audio_memo populates auto_tags, voice_distillation, creates ai_spark + document_links, and leaves raw_text/transcript_text 100% untouched."""
    cap_id = uuid.uuid4()
    device_id = uuid.uuid4()
    original_raw = "Spoken thoughts while walking dog about raft heartbeats and network partitions."
    original_transcript = "So I was thinking about the Raft consensus heartbeat interval and if we drop packets..."

    async with AsyncSessionLocal() as session:
        # Single active persona
        await session.execute(
            update(PersonaSnapshot).where(col(PersonaSnapshot.is_current).is_(True)).values(is_current=False)
        )
        persona_snap = PersonaSnapshot(
            version_number=int(uuid.uuid4().int % 100000),
            is_current=True,
            persona_json={"core_domains": ["distributed systems"], "active_projects": []},
            cached_prompt_prefix="### PROMPT PREFIX " * 300,
        )
        session.add(persona_snap)

        dev = Device(
            id=device_id,
            device_name=f"Audio-Worker-Dev-{uuid.uuid4().hex[:6]}",
            device_type="android",
            api_key_hash=hashlib.sha256(uuid.uuid4().bytes).hexdigest(),
        )
        session.add(dev)
        await session.flush()

        cap = Capture(
            id=cap_id,
            device_id=device_id,
            capture_type=CaptureTypeEnum.audio_memo,
            title="Dog Walk Thoughts on Raft",
            raw_text=original_raw,
            transcript_text=original_transcript,
            processing_status=ProcessingStatusEnum.INDEXED,
            captured_at=datetime.now(UTC),
        )
        session.add(cap)
        await session.commit()

    # Mock OpenAI client
    mock_eval = LunaCaptureEvaluation(
        auto_tags=["consensus", "raft", "networking"],
        voice_distillation=VoiceDistillationDraft(
            summary_bullets=["Raft heartbeat interval tuning", "Network partition behavior"],
            action_items=["Test heartbeat loss scenario with chaos proxy"],
        ),
        should_create_spark=True,
        novelty_score=0.88,
        spark_document=SparkDocumentDraft(
            title="Heartbeat Tuning in Consensus Networks",
            spark_markdown="# Heartbeat Tuning in Consensus Networks\n\nExpanding on voice memo...",
            spark_rationale="Connects dog walk thoughts to active distributed systems exploration",
            related_project_slug=None,
            connected_item_ids=[str(cap_id)],
        ),
        reminder=ReminderDraft(
            should_remind=True,
            reminder_type="TIME_SCHEDULED",
            title="Test Raft heartbeat loss",
            message="Check chaos proxy setup",
            delay_hours=24,
        ),
    )

    mock_client = MagicMock()
    mock_parse = AsyncMock()
    mock_choice = MagicMock()
    mock_choice.message.parsed = mock_eval
    mock_parse.return_value = MagicMock(choices=[mock_choice])
    mock_client.beta.chat.completions.parse = mock_parse
    set_openai_client(mock_client)

    # Run evaluation task
    await job_evaluate_spark_and_reminders(str(cap_id))

    async with AsyncSessionLocal() as session:
        updated_cap = await session.get(Capture, cap_id)
        assert updated_cap is not None

        # 1. Non-negotiable invariant: user_raw text and transcript_text NEVER mutated
        assert updated_cap.raw_text == original_raw
        assert updated_cap.transcript_text == original_transcript

        # 2. auto_tags populated
        assert "raft" in updated_cap.auto_tags
        assert "consensus" in updated_cap.auto_tags

        # 3. voice_distillation saved in extraction_metadata
        assert updated_cap.extraction_metadata is not None
        vd = updated_cap.extraction_metadata.get("voice_distillation")
        assert vd is not None
        assert "Raft heartbeat interval tuning" in vd["summary_bullets"]
        assert "Test heartbeat loss scenario with chaos proxy" in vd["action_items"]

        # 4. Status transitioned to SPARK_EVALUATED
        assert updated_cap.processing_status == ProcessingStatusEnum.SPARK_EVALUATED

        # 5. ai_sparks and document_links created
        links_res = await session.execute(
            select(DocumentLink).where(
                col(DocumentLink.target_id) == cap_id,
                col(DocumentLink.target_table) == "captures",
            )
        )
        links = links_res.scalars().all()
        assert len(links) >= 1
        spark_id = links[0].source_id

        spark = await session.get(AISpark, spark_id)
        assert spark is not None
        assert spark.title == "Heartbeat Tuning in Consensus Networks"
        assert "Expanding on voice memo" in spark.spark_markdown


@pytest.mark.asyncio
async def test_03_append_only_marginalia():
    """Calling POST /api/v1/captures/{id}/annotations creates capture_annotations row, updates annotations_concat & search_tsv, and leaves raw_text untouched."""
    raw_token = f"mem_live_{uuid.uuid4().hex}{uuid.uuid4().hex}"
    token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
    cap_id = uuid.uuid4()
    device_id = uuid.uuid4()
    original_raw = "Initial user thought about SQLite write performance in mobile apps."

    async with AsyncSessionLocal() as session:
        dev = Device(
            id=device_id,
            device_name=f"Marginalia-Dev-{uuid.uuid4().hex[:6]}",
            device_type="desktop",
            api_key_hash=token_hash,
        )
        session.add(dev)
        await session.flush()

        cap = Capture(
            id=cap_id,
            device_id=device_id,
            capture_type=CaptureTypeEnum.text_note,
            title="SQLite Mobile Benchmarks",
            raw_text=original_raw,
            annotations_concat="",
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
        resp = await client.post(
            f"/api/v1/captures/{cap_id}/annotations",
            headers=headers,
            json={"content": "WAL mode is essential when running background isolate queries."},
        )
        assert resp.status_code == 201
        data = resp.json()
        assert data["status"] == "CREATED"
        assert "WAL mode" in data["annotations_concat"]

    async with AsyncSessionLocal() as session:
        updated_cap = await session.get(Capture, cap_id)
        assert updated_cap is not None

        # 1. raw_text MUST remain 100% untouched
        assert updated_cap.raw_text == original_raw

        # 2. annotations_concat updated
        assert "[Annotation]: WAL mode is essential" in updated_cap.annotations_concat

        # 3. capture_annotations table has row
        annos_res = await session.execute(
            select(CaptureAnnotation).where(col(CaptureAnnotation.capture_id) == cap_id)
        )
        annos = annos_res.scalars().all()
        assert len(annos) == 1
        assert "WAL mode" in annos[0].content


@pytest.mark.asyncio
async def test_04_ask_memoria_and_spark_synthesis():
    """POST /api/v1/search/ask and POST /api/v1/sparks/synthesize return cited Markdown and persist ai_spark."""
    raw_token = f"mem_live_{uuid.uuid4().hex}{uuid.uuid4().hex}"
    token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
    cap1_id = uuid.uuid4()
    cap2_id = uuid.uuid4()
    device_id = uuid.uuid4()

    async with AsyncSessionLocal() as session:
        dev = Device(
            id=device_id,
            device_name=f"Ask-Dev-{uuid.uuid4().hex[:6]}",
            device_type="linux",
            api_key_hash=token_hash,
        )
        session.add(dev)
        await session.flush()

        c1 = Capture(
            id=cap1_id,
            device_id=device_id,
            capture_type=CaptureTypeEnum.text_note,
            title="Zero Trust Architecture",
            raw_text="Cloudflare Tunnel terminates mTLS at the edge before hitting our internal homelab ingress.",
            captured_at=datetime.now(UTC),
        )
        c2 = Capture(
            id=cap2_id,
            device_id=device_id,
            capture_type=CaptureTypeEnum.text_note,
            title="Service Token Authentication",
            raw_text="Headers CF-Access-Client-Id and CF-Access-Client-Secret protect all internal API routes.",
            captured_at=datetime.now(UTC),
        )
        session.add(c1)
        session.add(c2)
        await session.commit()

    headers = {
        "CF-Access-Client-Id": settings.CF_ACCESS_CLIENT_ID,
        "CF-Access-Client-Secret": settings.CF_ACCESS_CLIENT_SECRET,
        "Authorization": f"Bearer {raw_token}",
    }

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        # 1. Ask Memoria with save_as_spark=True
        ask_resp = await client.post(
            "/api/v1/search/ask",
            headers=headers,
            json={
                "question": "How do we secure edge ingress to our homelab?",
                "save_as_spark": True,
            },
        )
        assert ask_resp.status_code == 200
        ask_data = ask_resp.json()
        assert "answer_markdown" in ask_data
        assert ask_data["saved_spark_id"] is not None

        saved_spark_id = ask_data["saved_spark_id"]

        # 2. Intentional Synthesis of 2 Captures
        synth_resp = await client.post(
            "/api/v1/sparks/synthesize",
            headers=headers,
            json={
                "capture_ids": [str(cap1_id), str(cap2_id)],
                "user_angle": "Contrast edge termination vs service token verification",
            },
        )
        assert synth_resp.status_code == 201
        synth_data = synth_resp.json()
        assert "title" in synth_data
        assert "spark_markdown" in synth_data
        assert len(synth_data["connected_captures"]) == 2

    # Verify spark persisted in DB
    async with AsyncSessionLocal() as session:
        spark = await session.get(AISpark, uuid.UUID(saved_spark_id))
        assert spark is not None
        assert "Ask Memoria" in spark.title


@pytest.mark.asyncio
async def test_05_triage_decision_and_obsidian_export():
    """POST /api/v1/triage/{id}/decision updates triage state and GET /export.md outputs valid YAML frontmatter + [[wiki-links]]."""
    raw_token = f"mem_live_{uuid.uuid4().hex}{uuid.uuid4().hex}"
    token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
    cap_id = uuid.uuid4()
    spark_id = uuid.uuid4()
    device_id = uuid.uuid4()

    async with AsyncSessionLocal() as session:
        dev = Device(
            id=device_id,
            device_name=f"Triage-Dev-{uuid.uuid4().hex[:6]}",
            device_type="web",
            api_key_hash=token_hash,
        )
        session.add(dev)
        await session.flush()

        cap = Capture(
            id=cap_id,
            device_id=device_id,
            capture_type=CaptureTypeEnum.text_note,
            title="Proxmox Storage Architecture",
            raw_text="Use ZFS mirror for homelab storage pool to avoid data corruption.",
            is_triage_reviewed=False,
            captured_at=datetime.now(UTC),
        )
        session.add(cap)

        spark = AISpark(
            id=spark_id,
            title="ZFS Storage Resilience Strategy",
            spark_markdown="# ZFS Storage Resilience\n\nDetailed breakdown of scrub schedules.",
            spark_rationale="Derived from homelab storage notes",
            related_project="homelab-infra",
        )
        session.add(spark)

        link = DocumentLink(
            id=uuid.uuid4(),
            source_id=spark_id,
            source_table="ai_sparks",
            target_id=cap_id,
            target_table="captures",
            link_type=LinkTypeEnum.SPARK_SOURCE,
        )
        session.add(link)
        await session.commit()

    headers = {
        "CF-Access-Client-Id": settings.CF_ACCESS_CLIENT_ID,
        "CF-Access-Client-Secret": settings.CF_ACCESS_CLIENT_SECRET,
        "Authorization": f"Bearer {raw_token}",
    }

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        # 1. Triage decision: PIN_TO_PROJECT on capture
        decision_resp = await client.post(
            f"/api/v1/triage/{cap_id}/decision",
            headers=headers,
            json={"decision": "PIN_TO_PROJECT", "project_slug": "homelab-infra"},
        )
        assert decision_resp.status_code == 200
        assert decision_resp.json()["status"] == "OK"

        # 2. Export spark as Markdown
        export_resp = await client.get(
            f"/api/v1/sparks/{spark_id}/export.md",
            headers=headers,
        )
        assert export_resp.status_code == 200
        md_text = export_resp.text

        # Verify YAML frontmatter & wiki-links
        assert md_text.startswith("---")
        assert "type: ai_spark" in md_text
        assert "related_project: homelab-infra" in md_text
        assert f"[[{cap_id}|Proxmox Storage Architecture]]" in md_text
        assert "## Source Captures (Immutable)" in md_text
        assert "Use ZFS mirror for homelab storage" in md_text

    # Verify capture is now reviewed
    async with AsyncSessionLocal() as session:
        updated_cap = await session.get(Capture, cap_id)
        assert updated_cap is not None
        assert updated_cap.is_triage_reviewed is True
        assert "homelab-infra" in updated_cap.user_tags
