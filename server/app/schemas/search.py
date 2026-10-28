import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class SearchRequest(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    query: str = Field(min_length=1, description="Search query string")
    top_k: int = Field(default=15, ge=1, le=50, description="Max results to return")
    min_similarity: float = Field(
        default=0.45, ge=0.0, le=1.0, description="Minimum cosine similarity cutoff"
    )
    filter_types: list[str] | None = Field(
        default=None,
        description="Optional list of capture_types or 'ai_spark' to filter by",
    )
    include_archived: bool = Field(default=False, description="Whether to include archived notes")


class SearchResultItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    item_id: uuid.UUID
    item_table: str
    item_type: str
    title: str | None = None
    snippet: str
    modality_composition: str | None = None
    semantic_similarity: float
    keyword_score: float
    rrf_score: float
    item_timestamp: datetime


class SearchResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    query: str
    top_k: int
    query_time_ms: float
    results: list[SearchResultItem]
