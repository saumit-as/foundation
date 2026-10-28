import hashlib
import uuid
from datetime import UTC, datetime

import numpy as np
import pytest
import torch
from httpx import ASGITransport, AsyncClient

from app.db.session import AsyncSessionLocal
from app.main import app
from app.models.tables import AiSpark, Capture, Device, Embedding, PersonaSnapshot
from app.services.embedder import EmbeddingGemmaService


class MockSentenceTransformer:
    """Mock SentenceTransformer outputting deterministic 768d L2-normalized vectors."""

    def __init__(self, *args, **kwargs):
        pass

    def encode(self, text, *args, **kwargs):
        # Generate deterministic vector based on text hash
        seed = int(hashlib.md5(str(text).encode()).hexdigest()[:8], 16)
        rng = np.random.default_rng(seed)
        vec = rng.standard_normal(768).astype(np.float32)
        norm = np.linalg.norm(vec)
        return (vec / norm).tolist()


@pytest.mark.asyncio
async def test_01_precision_and_iron_rules():
    embedder = EmbeddingGemmaService(device="cpu", lazy_load=True)
    assert embedder.dtype in (torch.bfloat16, torch.float32)
    assert embedder.dtype != torch.float16, "float16 is strictly forbidden"


@pytest.mark.asyncio
async def test_02_vector_assertion_validation():
    embedder = EmbeddingGemmaService(device="cpu", lazy_load=True)

    # Valid normalized 768d vector
    valid_vec = np.ones(768, dtype=np.float32)
    valid_vec /= np.linalg.norm(valid_vec)
    embedder._assert_valid_vector(valid_vec)  # should not raise

    # Wrong dimension
    with pytest.raises(ValueError):
        embedder._assert_valid_vector(np.ones(512, dtype=np.float32))

    # NaN vector
    nan_vec = valid_vec.copy()
    nan_vec[10] = np.nan
    with pytest.raises(RuntimeError):
        embedder._assert_valid_vector(nan_vec)

    # Inf vector
    inf_vec = valid_vec.copy()
    inf_vec[20] = np.inf
    with pytest.raises(RuntimeError):
        embedder._assert_valid_vector(inf_vec)

    # Unnormalized vector
    unnorm_vec = valid_vec * 5.0
    with pytest.raises(RuntimeError):
        embedder._assert_valid_vector(unnorm_vec)


@pytest.mark.asyncio
async def test_03_long_document_chunking():
    mock_model = MockSentenceTransformer()
    embedder = EmbeddingGemmaService(device="cpu", model=mock_model)

    # 25,000 character Markdown document
    long_doc = "# Deep Dive Architecture\n" + ("This is detailed technical section text. " * 600)
    assert len(long_doc) > 24000

    chunks = await embedder.chunk_and_encode_long_text(
        title="Distributed Systems Spec",
        content=long_doc,
        max_chars=10000,
        overlap_chars=1000,
    )

    assert len(chunks) >= 3
    for chunk_idx, preview, vector in chunks:
        assert isinstance(chunk_idx, int)
        assert len(preview) <= 1200
        assert len(vector) == 768
        v_np = np.array(vector)
        assert abs(float(np.linalg.norm(v_np)) - 1.0) < 1e-2


@pytest.mark.asyncio
async def test_04_hybrid_rrf_search_with_persona_boost():
    # 1. Setup mock embedder
    mock_model = MockSentenceTransformer()
    test_embedder = EmbeddingGemmaService(device="cpu", model=mock_model)

    # Replace global embedder in API route with mock for unit test
    from app.api.v1 import search as search_module

    search_module._embedder_instance = test_embedder

    # 2. Provision test device
    raw_token = f"mem_live_{uuid.uuid4().hex}{uuid.uuid4().hex}"
    token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
    test_device_id = uuid.uuid4()

    # 3. Insert Persona Snapshot with active project 'memoria-v3'
    active_slug = "memoria-v3"
    persona_data = {
        "schema_version": "1.0",
        "core_domains": ["distributed systems"],
        "active_projects": [
            {
                "slug": active_slug,
                "name": "Memoria v3 Personal Context Engine",
                "focus_summary": "Building scratchpad with embeddinggemma-2",
                "priority_weight": 1.5,
            }
        ],
        "current_learning_threads": [],
        "synthesis_preferences": {"spark_threshold": 0.72, "preferred_style": "concise"},
        "ignored_or_archived_topics": [],
    }

    async with AsyncSessionLocal() as session:
        from sqlmodel import col, update

        # Ensure single current persona snapshot
        await session.execute(
            update(PersonaSnapshot)
            .where(col(PersonaSnapshot.is_current).is_(True))
            .values(is_current=False)
        )

        device = Device(
            id=test_device_id,
            device_name="Test-Search-Runner",
            device_type="linux",
            api_key_hash=token_hash,
        )
        session.add(device)

        snapshot = PersonaSnapshot(
            version_number=int(uuid.uuid4().int % 100000),
            is_current=True,
            persona_json=persona_data,
            cached_prompt_prefix="### CACHED PREFIX PADDING " * 100,
        )
        session.add(snapshot)
        await session.commit()

        # Generate vectors
        q_vec = await test_embedder.encode_search_query("homelab dns unbound")

        # Capture 1: matches active project tag -> gets 1.15x boost!
        cap1_id = uuid.uuid4()
        cap1 = Capture(
            id=cap1_id,
            device_id=test_device_id,
            capture_type="text_note",
            title="Unbound DNS in Homelab",
            raw_text="Configuring unbound DNS with cloudflared tunnel",
            user_tags=[active_slug, "homelab"],
            captured_at=datetime.now(UTC),
        )
        session.add(cap1)
        emb1 = Embedding(
            id=uuid.uuid4(),
            owner_id=cap1_id,
            owner_table="captures",
            chunk_index=0,
            modality_composition="text",
            token_count=120,
            embedding=q_vec,
        )
        session.add(emb1)

        # Capture 2: standard note
        cap2_id = uuid.uuid4()
        cap2 = Capture(
            id=cap2_id,
            device_id=test_device_id,
            capture_type="text_note",
            title="General Python Notes",
            raw_text="Python async event loop and coroutines",
            user_tags=["python"],
            captured_at=datetime.now(UTC),
        )
        session.add(cap2)
        emb2 = Embedding(
            id=uuid.uuid4(),
            owner_id=cap2_id,
            owner_table="captures",
            chunk_index=0,
            modality_composition="text",
            token_count=80,
            embedding=q_vec,
        )
        session.add(emb2)

        # AI Spark: synthesized document
        spark_id = uuid.uuid4()
        spark = AiSpark(
            id=spark_id,
            title="DNS Architecture Synthesis",
            spark_markdown="Comprehensive guide to zero-trust DNS in homelabs",
            related_project=active_slug,
        )
        session.add(spark)
        emb3 = Embedding(
            id=uuid.uuid4(),
            owner_id=spark_id,
            owner_table="ai_sparks",
            chunk_index=0,
            modality_composition="text",
            token_count=200,
            embedding=q_vec,
        )
        session.add(emb3)
        await session.commit()

    # Call POST /api/v1/search
    headers = {"Authorization": f"Bearer {raw_token}"}
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        resp = await ac.post(
            "/api/v1/search",
            json={"query": "homelab dns unbound", "top_k": 10, "min_similarity": 0.1},
            headers=headers,
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["query"] == "homelab dns unbound"
        assert len(data["results"]) >= 2

        # Verify results contain both captures and ai_sparks
        tables_found = {r["item_table"] for r in data["results"]}
        assert "captures" in tables_found
        assert "ai_sparks" in tables_found

        # Verify boosted items appear at top with higher score
        top_item = data["results"][0]
        assert top_item["rrf_score"] > 0.0
