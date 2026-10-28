import asyncio
import sys
import uuid
from datetime import UTC, datetime

from sqlalchemy import text

from app.db.session import async_engine
from app.models.enums import CaptureTypeEnum, ProcessingStatusEnum

EXPECTED_TABLES = [
    "devices",
    "reading_sessions",
    "captures",
    "capture_annotations",
    "media_assets",
    "ai_sparks",
    "document_links",
    "embeddings",
    "persona_snapshots",
    "reminders",
]


async def verify() -> None:
    async with async_engine.connect() as conn:
        # 1. Assert all 10 tables exist
        result = await conn.execute(
            text("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")
        )
        existing_tables = {row[0] for row in result.fetchall()}
        for table in EXPECTED_TABLES:
            if table not in existing_tables:
                print(f"FAILED: Missing table {table}. Found: {existing_tables}")
                sys.exit(1)
        print("✓ All 10 tables exist in PostgreSQL")

        # 2. Assert idx_embeddings_hnsw_cosine exists
        idx_result = await conn.execute(
            text(
                "SELECT indexname FROM pg_indexes "
                "WHERE tablename = 'embeddings' AND indexname = 'idx_embeddings_hnsw_cosine';"
            )
        )
        if not idx_result.fetchone():
            print("FAILED: Missing HNSW index idx_embeddings_hnsw_cosine")
            sys.exit(1)
        print("✓ HNSW index idx_embeddings_hnsw_cosine verified")

        # 3. Test insert with trigger and TSVector generation, then roll back
        savepoint = await conn.begin_nested()
        test_id = uuid.uuid4()
        now = datetime.now(UTC)
        insert_sql = text("""
            INSERT INTO captures (
                id, capture_type, processing_status, title, raw_text, captured_at
            ) VALUES (
                :id, :capture_type, :processing_status, :title, :raw_text, :captured_at
            ) RETURNING sync_version, search_tsv;
        """)
        ins_res = await conn.execute(
            insert_sql,
            {
                "id": test_id,
                "capture_type": CaptureTypeEnum.text_note.value,
                "processing_status": ProcessingStatusEnum.QUEUED.value,
                "title": "Homelab Architecture Note",
                "raw_text": "Need to test vector cosine similarity with embeddinggemma-2",
                "captured_at": now,
            },
        )
        row = ins_res.fetchone()
        if not row:
            print("FAILED: Insert returned no rows")
            await savepoint.rollback()
            sys.exit(1)

        sync_version, search_tsv = row[0], row[1]
        if sync_version is None or sync_version < 1:
            print(f"FAILED: sync_version trigger did not fire properly: {sync_version}")
            await savepoint.rollback()
            sys.exit(1)

        if not search_tsv:
            print("FAILED: search_tsv TSVector was not generated")
            await savepoint.rollback()
            sys.exit(1)

        print(f"✓ Trigger assigned sync_version={sync_version}, TSVector generated={search_tsv}")
        await savepoint.rollback()
        print("✓ Savepoint rolled back cleanly")

    print("TASK_02_SCHEMA_VERIFIED_OK")
    sys.exit(0)


if __name__ == "__main__":
    asyncio.run(verify())
