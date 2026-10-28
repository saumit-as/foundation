from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_device
from app.db.session import get_async_session
from app.models.tables import Device
from app.schemas.search import SearchRequest, SearchResponse
from app.services.embedder import EmbeddingGemmaService
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
