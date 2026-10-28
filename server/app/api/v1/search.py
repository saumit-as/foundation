import uuid
from typing import Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col, select

from app.core.security import get_current_device
from app.db.session import get_async_session
from app.models.enums import LinkTypeEnum
from app.models.tables import AISpark, Device, DocumentLink, Embedding, PersonaSnapshot
from app.schemas.search import SearchRequest, SearchResponse
from app.services.embedder import EmbeddingGemmaService
from app.services.luna_agent import LunaAgentService, LunaAskResponse
from app.services.search import execute_hybrid_search

router = APIRouter()
_embedder_instance: EmbeddingGemmaService | None = None


def get_embedder_service() -> EmbeddingGemmaService:
    global _embedder_instance
    if _embedder_instance is None:
        _embedder_instance = EmbeddingGemmaService(lazy_load=True)
    return _embedder_instance


@router.post(
    "/search",
    response_model=SearchResponse,
    summary="Multimodal Hybrid RRF Search (EmbeddingGemma 2 768d + BM25 + Persona Boost)",
)
async def hybrid_search_endpoint(
    request: SearchRequest,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
    embedder: EmbeddingGemmaService = Depends(get_embedder_service),
) -> SearchResponse:
    return await execute_hybrid_search(request, session, embedder)


class AskMemoriaRequest(BaseModel):
    question: str = Field(..., min_length=2)
    save_as_spark: bool = False
    limit: int = Field(default=8, ge=1, le=20)


class AskMemoriaResponse(LunaAskResponse):
    saved_spark_id: uuid.UUID | None = None


@router.post(
    "/search/ask",
    response_model=AskMemoriaResponse,
    summary="'Ask Memoria' Grounded Conversational RAG",
)
async def ask_memoria_endpoint(
    request: AskMemoriaRequest,
    device: Device = Depends(get_current_device),
    session: AsyncSession = Depends(get_async_session),
    embedder: EmbeddingGemmaService = Depends(get_embedder_service),
) -> AskMemoriaResponse:
    # 1. Retrieve grounded context
    search_req = SearchRequest(query=request.question, limit=request.limit)
    search_res = await execute_hybrid_search(search_req, session, embedder)

    # 2. Load cached prompt prefix
    stmt = (
        select(PersonaSnapshot)
        .where(col(PersonaSnapshot.is_current).is_(True))
        .order_by(col(PersonaSnapshot.version_number).desc())
        .limit(1)
    )
    res = await session.execute(stmt)
    snapshot = res.scalar_one_or_none()
    cached_prefix = (
        snapshot.cached_prompt_prefix
        if snapshot
        else "You are Memoria Context Engine background synthesizer."
    )

    # 3. Call gpt-6-luna Ask Memoria
    luna = LunaAgentService()
    rag_items: list[dict[str, Any]] = [
        {
            "item_id": str(i.item_id),
            "item_table": i.item_table,
            "title": i.title,
            "snippet": i.snippet,
        }
        for i in search_res.results
    ]
    luna_resp = await luna.ask_memoria(request.question, rag_items, cached_prefix)

    saved_spark_id: uuid.UUID | None = None
    if request.save_as_spark:
        saved_spark_id = uuid.uuid4()
        spark = AISpark(
            id=saved_spark_id,
            title=f"Ask Memoria: {request.question[:60]}",
            spark_markdown=luna_resp.answer_markdown,
            spark_rationale=f"Grounded response for user query: {request.question}",
        )
        session.add(spark)

        # Link cited sources
        for cited in luna_resp.cited_items:
            try:
                target_uuid = uuid.UUID(cited.item_id)
                link = DocumentLink(
                    id=uuid.uuid4(),
                    source_id=saved_spark_id,
                    source_table="ai_sparks",
                    target_id=target_uuid,
                    target_table=cited.item_table,
                    link_type=LinkTypeEnum.SPARK_SOURCE,
                )
                session.add(link)
            except Exception:
                pass

        # Embed spark
        vec = await embedder.encode_text_document(spark.title, spark.spark_markdown)
        emb_stmt = (
            pg_insert(Embedding)
            .values(
                id=uuid.uuid4(),
                owner_id=saved_spark_id,
                owner_table="ai_sparks",
                chunk_index=0,
                modality_composition="text",
                chunk_preview_text=spark.spark_markdown[:1200],
                token_count=len(spark.spark_markdown.split()),
                embedding=vec,
            )
            .on_conflict_do_update(
                index_elements=["owner_id", "owner_table", "chunk_index"],
                set_={
                    "chunk_preview_text": spark.spark_markdown[:1200],
                    "token_count": len(spark.spark_markdown.split()),
                    "embedding": vec,
                },
            )
        )
        await session.execute(emb_stmt)
        await session.commit()

    return AskMemoriaResponse(
        answer_markdown=luna_resp.answer_markdown,
        cited_items=luna_resp.cited_items,
        follow_up_questions=luna_resp.follow_up_questions,
        saved_spark_id=saved_spark_id,
    )

