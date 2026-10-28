import time

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col, select

from app.models.tables import PersonaSnapshot
from app.schemas.search import SearchRequest, SearchResponse, SearchResultItem
from app.services.embedder import EmbeddingGemmaService

ALL_FILTER_TYPES = [
    "text_note",
    "article_url",
    "pdf_document",
    "video_reel",
    "image_upload",
    "book_scan",
    "audio_memo",
    "ai_spark",
]

HYBRID_RRF_SQL = text("""
WITH best_vector_per_item AS (
    SELECT DISTINCT ON (e.owner_id, e.owner_table)
        e.owner_id,
        e.owner_table,
        e.modality_composition,
        e.chunk_preview_text,
        1 - (e.embedding <=> CAST(:query_vector AS vector(768))) AS cosine_sim
    FROM embeddings e
    WHERE 1 - (e.embedding <=> CAST(:query_vector AS vector(768))) >= :min_similarity
    ORDER BY e.owner_id, e.owner_table, (e.embedding <=> CAST(:query_vector AS vector(768))) ASC
),
vector_matches AS (
    SELECT
        owner_id,
        owner_table,
        modality_composition,
        chunk_preview_text,
        cosine_sim,
        ROW_NUMBER() OVER (ORDER BY cosine_sim DESC) AS vec_rank
    FROM best_vector_per_item
    ORDER BY cosine_sim DESC
    LIMIT 40
),
raw_fts_matches AS (
    SELECT
        c.id AS owner_id,
        CAST('captures' AS varchar(32)) AS owner_table,
        ts_rank_cd(c.search_tsv, websearch_to_tsquery('english', :query_text)) AS fts_score
    FROM captures c
    WHERE c.search_tsv @@ websearch_to_tsquery('english', :query_text)
      AND NOT c.is_deleted
      AND (:include_archived = TRUE OR NOT c.is_archived)
    UNION ALL
    SELECT
        s.id AS owner_id,
        CAST('ai_sparks' AS varchar(32)) AS owner_table,
        ts_rank_cd(s.search_tsv, websearch_to_tsquery('english', :query_text)) AS fts_score
    FROM ai_sparks s
    WHERE s.search_tsv @@ websearch_to_tsquery('english', :query_text)
      AND NOT s.is_dismissed
),
fts_matches AS (
    SELECT
        owner_id,
        owner_table,
        fts_score,
        ROW_NUMBER() OVER (ORDER BY fts_score DESC) AS fts_rank
    FROM raw_fts_matches
    ORDER BY fts_score DESC
    LIMIT 40
),
fused AS (
    SELECT
        COALESCE(v.owner_id, f.owner_id) AS item_id,
        COALESCE(v.owner_table, f.owner_table) AS item_table,
        v.modality_composition,
        v.chunk_preview_text,
        COALESCE(v.cosine_sim, 0.0) AS semantic_similarity,
        COALESCE(f.fts_score, 0.0) AS keyword_score,
        (COALESCE(0.70 / (60 + v.vec_rank), 0.0) + COALESCE(0.30 / (60 + f.fts_rank), 0.0)) AS base_rrf_score
    FROM vector_matches v
    FULL OUTER JOIN fts_matches f
        ON v.owner_id = f.owner_id AND v.owner_table = f.owner_table
)
SELECT
    fused.item_id,
    fused.item_table,
    COALESCE(CAST(c.capture_type AS text), 'ai_spark') AS item_type,
    COALESCE(c.title, c.extracted_title, s.title) AS title,
    COALESCE(fused.chunk_preview_text, LEFT(COALESCE(c.raw_text, s.spark_markdown), 400)) AS snippet,
    fused.modality_composition,
    fused.semantic_similarity,
    fused.keyword_score,
    fused.base_rrf_score * (
        CASE
            WHEN s.related_project = ANY(:active_project_slugs)
              OR (c.auto_tags && :active_project_slugs)
              OR (c.user_tags && :active_project_slugs)
            THEN 1.15
            ELSE 1.0
        END
    ) AS rrf_score,
    COALESCE(c.captured_at, s.created_at) AS item_timestamp
FROM fused
LEFT JOIN captures c ON fused.item_table = 'captures' AND fused.item_id = c.id
LEFT JOIN ai_sparks s ON fused.item_table = 'ai_sparks' AND fused.item_id = s.id
WHERE (
    (fused.item_table = 'captures' AND NOT c.is_deleted AND (:include_archived = TRUE OR NOT c.is_archived))
    OR (fused.item_table = 'ai_sparks' AND NOT s.is_dismissed)
)
  AND (COALESCE(CAST(c.capture_type AS text), 'ai_spark') = ANY(:filter_types))
ORDER BY rrf_score DESC
LIMIT :top_k;
""")


async def execute_hybrid_search(
    req: SearchRequest,
    session: AsyncSession,
    embedder: EmbeddingGemmaService,
) -> SearchResponse:
    start_time = time.perf_counter()

    # 1. Fetch current active project slugs from persona snapshot
    snap_res = await session.execute(
        select(PersonaSnapshot).where(col(PersonaSnapshot.is_current).is_(True))
    )
    current_persona = snap_res.scalar_one_or_none()
    active_slugs: list[str] = []
    if current_persona and isinstance(current_persona.persona_json, dict):
        active_projects = current_persona.persona_json.get("active_projects", [])
        active_slugs = [p.get("slug") for p in active_projects if p.get("slug")]

    if not active_slugs:
        active_slugs = ["_no_active_project_"]

    # 2. Encode search query into 768d vector
    query_vector = await embedder.encode_search_query(req.query)
    vector_str = f"[{','.join(f'{x:.8f}' for x in query_vector)}]"

    # 3. Determine filter types
    filters = req.filter_types if req.filter_types else ALL_FILTER_TYPES

    # 4. Execute hybrid RRF SQL
    rows = await session.execute(
        HYBRID_RRF_SQL,
        {
            "query_vector": vector_str,
            "min_similarity": req.min_similarity,
            "query_text": req.query,
            "include_archived": req.include_archived,
            "active_project_slugs": active_slugs,
            "filter_types": filters,
            "top_k": req.top_k,
        },
    )

    results = []
    for row in rows.mappings():
        item = SearchResultItem(
            item_id=row["item_id"],
            item_table=row["item_table"],
            item_type=row["item_type"],
            title=row["title"],
            snippet=row["snippet"] or "",
            modality_composition=row["modality_composition"],
            semantic_similarity=float(row["semantic_similarity"]),
            keyword_score=float(row["keyword_score"]),
            rrf_score=float(row["rrf_score"]),
            item_timestamp=row["item_timestamp"],
        )
        results.append(item)

    elapsed_ms = (time.perf_counter() - start_time) * 1000.0
    return SearchResponse(
        query=req.query,
        top_k=req.top_k,
        query_time_ms=elapsed_ms,
        results=results,
    )
