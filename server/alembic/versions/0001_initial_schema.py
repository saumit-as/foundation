"""Initial schema migration: 10 tables, enums, triggers, GIN and HNSW vector index

Revision ID: 0001_initial_schema
Revises: 
Create Date: 2026-10-29 02:20:00.000000

"""
from alembic import op

revision = "0001_initial_schema"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. Extensions
    op.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";')
    op.execute('CREATE EXTENSION IF NOT EXISTS "vector";')
    op.execute('CREATE EXTENSION IF NOT EXISTS "pg_trgm";')

    # 2. Enums
    op.execute("""
    DO $$ BEGIN
        CREATE TYPE capture_type_enum AS ENUM (
            'text_note',
            'article_url',
            'pdf_document',
            'video_reel',
            'image_upload',
            'book_scan',
            'audio_memo'
        );
    EXCEPTION
        WHEN duplicate_object THEN null;
    END $$;
    """)

    op.execute("""
    DO $$ BEGIN
        CREATE TYPE processing_status_enum AS ENUM (
            'QUEUED',
            'EXTRACTING_MEDIA',
            'EXTRACTION_PARTIAL',
            'EMBEDDING',
            'INDEXED',
            'SPARK_EVALUATED',
            'FAILED_RETRYABLE',
            'DEAD_LETTER'
        );
    EXCEPTION
        WHEN duplicate_object THEN null;
    END $$;
    """)

    op.execute("""
    DO $$ BEGIN
        CREATE TYPE link_type_enum AS ENUM (
            'SPARK_SOURCE',
            'SEMANTIC_RELATED',
            'USER_MANUAL_LINK',
            'THREAD_CONTINUATION'
        );
    EXCEPTION
        WHEN duplicate_object THEN null;
    END $$;
    """)

    op.execute("""
    DO $$ BEGIN
        CREATE TYPE reminder_type_enum AS ENUM (
            'TIME_SCHEDULED',
            'CONTEXTUAL_MATCH',
            'SPACED_REVIEW'
        );
    EXCEPTION
        WHEN duplicate_object THEN null;
    END $$;
    """)

    # 3. Global Sync Sequence & Trigger Function
    op.execute("CREATE SEQUENCE IF NOT EXISTS global_sync_seq START 1;")

    op.execute("""
    CREATE OR REPLACE FUNCTION bump_sync_version()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = NOW();
        NEW.sync_version = nextval('global_sync_seq');
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """)

    # 4. Tables
    # 4.1 devices
    op.execute("""
    CREATE TABLE IF NOT EXISTS devices (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        device_name VARCHAR(120) NOT NULL,
        device_type VARCHAR(32) NOT NULL,
        api_key_hash VARCHAR(255) NOT NULL UNIQUE,
        last_sync_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        is_revoked BOOLEAN NOT NULL DEFAULT FALSE
    );
    """)

    # 4.2 reading_sessions
    op.execute("""
    CREATE TABLE IF NOT EXISTS reading_sessions (
        id UUID PRIMARY KEY,
        source_title VARCHAR(512) NOT NULL,
        author VARCHAR(255),
        isbn_or_url TEXT,
        default_tags TEXT[] NOT NULL DEFAULT '{book}',
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        sync_version BIGINT NOT NULL DEFAULT 1
    );
    """)

    # 4.3 captures
    op.execute("""
    CREATE TABLE IF NOT EXISTS captures (
        id UUID PRIMARY KEY,
        device_id UUID REFERENCES devices(id) ON DELETE SET NULL,
        reading_session_id UUID REFERENCES reading_sessions(id) ON DELETE SET NULL,
        capture_type capture_type_enum NOT NULL,
        processing_status processing_status_enum NOT NULL DEFAULT 'QUEUED',
        title VARCHAR(512),
        raw_text TEXT,
        source_url TEXT,
        page_range VARCHAR(64),
        user_tags TEXT[] NOT NULL DEFAULT '{}',
        canonical_url TEXT,
        domain VARCHAR(255),
        extracted_title VARCHAR(512),
        extracted_markdown TEXT,
        ocr_text TEXT,
        transcript_text TEXT,
        annotations_concat TEXT NOT NULL DEFAULT '',
        auto_tags TEXT[] NOT NULL DEFAULT '{}',
        extraction_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
        search_tsv TSVECTOR GENERATED ALWAYS AS (
            setweight(to_tsvector('english', coalesce(title, '') || ' ' || coalesce(extracted_title, '')), 'A') ||
            setweight(to_tsvector('english', coalesce(raw_text, '') || ' ' || coalesce(annotations_concat, '')), 'A') ||
            setweight(to_tsvector('english', coalesce(ocr_text, '') || ' ' || coalesce(transcript_text, '')), 'B') ||
            setweight(to_tsvector('english', coalesce(extracted_markdown, '')), 'C')
        ) STORED,
        captured_at TIMESTAMPTZ NOT NULL,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        is_triage_reviewed BOOLEAN NOT NULL DEFAULT FALSE,
        is_archived BOOLEAN NOT NULL DEFAULT FALSE,
        is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
        sync_version BIGINT NOT NULL DEFAULT 1
    );
    """)

    op.execute("CREATE INDEX IF NOT EXISTS idx_captures_status ON captures(processing_status) WHERE NOT is_deleted;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_captures_captured_at ON captures(captured_at DESC);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_captures_triage ON captures(captured_at DESC) WHERE NOT is_triage_reviewed AND NOT is_archived AND NOT is_deleted;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_captures_sync_version ON captures(sync_version);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_captures_search_tsv ON captures USING GIN (search_tsv);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_captures_user_tags ON captures USING GIN (user_tags);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_captures_auto_tags ON captures USING GIN (auto_tags);")

    # 4.4 capture_annotations
    op.execute("""
    CREATE TABLE IF NOT EXISTS capture_annotations (
        id UUID PRIMARY KEY,
        capture_id UUID NOT NULL REFERENCES captures(id) ON DELETE CASCADE,
        content TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        sync_version BIGINT NOT NULL DEFAULT 1
    );
    """)
    op.execute("CREATE INDEX IF NOT EXISTS idx_capture_annotations_capture_id ON capture_annotations(capture_id, created_at ASC);")

    # 4.5 media_assets
    op.execute("""
    CREATE TABLE IF NOT EXISTS media_assets (
        id UUID PRIMARY KEY,
        capture_id UUID NOT NULL REFERENCES captures(id) ON DELETE CASCADE,
        media_kind VARCHAR(32) NOT NULL,
        page_order INT NOT NULL DEFAULT 0,
        local_rel_path TEXT NOT NULL,
        mime_type VARCHAR(127) NOT NULL,
        file_size_bytes BIGINT NOT NULL,
        sha256_checksum CHAR(64) NOT NULL,
        duration_seconds FLOAT,
        width_px INT,
        height_px INT,
        soft_token_budget INT DEFAULT 280,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
    """)
    op.execute("CREATE INDEX IF NOT EXISTS idx_media_assets_capture_id ON media_assets(capture_id);")

    # 4.6 ai_sparks
    op.execute("""
    CREATE TABLE IF NOT EXISTS ai_sparks (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        title VARCHAR(512) NOT NULL,
        spark_markdown TEXT NOT NULL,
        spark_rationale TEXT,
        related_project VARCHAR(255),
        tags TEXT[] NOT NULL DEFAULT '{}',
        model_id VARCHAR(64) NOT NULL DEFAULT 'gpt-6-luna',
        prompt_cache_hit BOOLEAN DEFAULT TRUE,
        search_tsv TSVECTOR GENERATED ALWAYS AS (
            setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
            setweight(to_tsvector('english', coalesce(spark_markdown, '')), 'B')
        ) STORED,
        is_read BOOLEAN NOT NULL DEFAULT FALSE,
        is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
        is_dismissed BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        sync_version BIGINT NOT NULL DEFAULT 1
    );
    """)
    op.execute("CREATE INDEX IF NOT EXISTS idx_ai_sparks_search_tsv ON ai_sparks USING GIN (search_tsv);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_ai_sparks_sync_version ON ai_sparks(sync_version);")

    # 4.7 document_links
    op.execute("""
    CREATE TABLE IF NOT EXISTS document_links (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        source_id UUID NOT NULL,
        source_table VARCHAR(32) NOT NULL CHECK (source_table IN ('captures', 'ai_sparks')),
        target_id UUID NOT NULL,
        target_table VARCHAR(32) NOT NULL CHECK (target_table IN ('captures', 'ai_sparks')),
        link_type link_type_enum NOT NULL,
        similarity_score FLOAT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        UNIQUE (source_id, target_id, link_type)
    );
    """)
    op.execute("CREATE INDEX IF NOT EXISTS idx_doc_links_source ON document_links(source_id, source_table);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_doc_links_target ON document_links(target_id, target_table);")

    # 4.8 embeddings
    op.execute("""
    CREATE TABLE IF NOT EXISTS embeddings (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        owner_id UUID NOT NULL,
        owner_table VARCHAR(32) NOT NULL CHECK (owner_table IN ('captures', 'ai_sparks')),
        chunk_index INT NOT NULL DEFAULT 0,
        modality_composition VARCHAR(64) NOT NULL,
        token_count INT NOT NULL CHECK (token_count <= 8192),
        chunk_preview_text TEXT,
        embedding VECTOR(768) NOT NULL,
        model_version VARCHAR(64) NOT NULL DEFAULT 'google/embeddinggemma-2',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        UNIQUE (owner_id, owner_table, chunk_index)
    );
    """)
    op.execute("""
    CREATE INDEX IF NOT EXISTS idx_embeddings_hnsw_cosine
    ON embeddings USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 128);
    """)
    op.execute("CREATE INDEX IF NOT EXISTS idx_embeddings_owner ON embeddings(owner_id, owner_table);")

    # 4.9 persona_snapshots
    op.execute("""
    CREATE TABLE IF NOT EXISTS persona_snapshots (
        id SERIAL PRIMARY KEY,
        version_number INT NOT NULL UNIQUE,
        is_current BOOLEAN NOT NULL DEFAULT TRUE,
        persona_json JSONB NOT NULL,
        cached_prompt_prefix TEXT NOT NULL,
        summary_diff TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
    """)
    op.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_persona_single_current ON persona_snapshots(is_current) WHERE is_current = TRUE;")

    # 4.10 reminders
    op.execute("""
    CREATE TABLE IF NOT EXISTS reminders (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        target_id UUID NOT NULL,
        target_table VARCHAR(32) NOT NULL CHECK (target_table IN ('captures', 'ai_sparks')),
        reminder_type reminder_type_enum NOT NULL,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        deep_link_uri TEXT NOT NULL,
        scheduled_for TIMESTAMPTZ NOT NULL,
        dispatched_at TIMESTAMPTZ,
        ntfy_message_id VARCHAR(128),
        is_acknowledged BOOLEAN NOT NULL DEFAULT FALSE,
        snoozed_until TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        sync_version BIGINT NOT NULL DEFAULT 1
    );
    """)
    op.execute("CREATE INDEX IF NOT EXISTS idx_reminders_due ON reminders(scheduled_for) WHERE dispatched_at IS NULL AND NOT is_acknowledged;")

    # 5. Triggers for sync_version (one command per op.execute)
    op.execute("DROP TRIGGER IF EXISTS trg_captures_sync_version ON captures;")
    op.execute("""
    CREATE TRIGGER trg_captures_sync_version
    BEFORE INSERT OR UPDATE ON captures
    FOR EACH ROW EXECUTE FUNCTION bump_sync_version();
    """)

    op.execute("DROP TRIGGER IF EXISTS trg_sparks_sync_version ON ai_sparks;")
    op.execute("""
    CREATE TRIGGER trg_sparks_sync_version
    BEFORE INSERT OR UPDATE ON ai_sparks
    FOR EACH ROW EXECUTE FUNCTION bump_sync_version();
    """)

    op.execute("DROP TRIGGER IF EXISTS trg_reminders_sync_version ON reminders;")
    op.execute("""
    CREATE TRIGGER trg_reminders_sync_version
    BEFORE INSERT OR UPDATE ON reminders
    FOR EACH ROW EXECUTE FUNCTION bump_sync_version();
    """)

    op.execute("DROP TRIGGER IF EXISTS trg_reading_sessions_sync_version ON reading_sessions;")
    op.execute("""
    CREATE TRIGGER trg_reading_sessions_sync_version
    BEFORE INSERT OR UPDATE ON reading_sessions
    FOR EACH ROW EXECUTE FUNCTION bump_sync_version();
    """)

    op.execute("DROP TRIGGER IF EXISTS trg_capture_annotations_sync_version ON capture_annotations;")
    op.execute("""
    CREATE TRIGGER trg_capture_annotations_sync_version
    BEFORE INSERT OR UPDATE ON capture_annotations
    FOR EACH ROW EXECUTE FUNCTION bump_sync_version();
    """)


def downgrade() -> None:
    op.execute("DROP TRIGGER IF EXISTS trg_capture_annotations_sync_version ON capture_annotations;")
    op.execute("DROP TRIGGER IF EXISTS trg_reading_sessions_sync_version ON reading_sessions;")
    op.execute("DROP TRIGGER IF EXISTS trg_reminders_sync_version ON reminders;")
    op.execute("DROP TRIGGER IF EXISTS trg_sparks_sync_version ON ai_sparks;")
    op.execute("DROP TRIGGER IF EXISTS trg_captures_sync_version ON captures;")

    op.execute("DROP TABLE IF EXISTS reminders CASCADE;")
    op.execute("DROP TABLE IF EXISTS persona_snapshots CASCADE;")
    op.execute("DROP TABLE IF EXISTS embeddings CASCADE;")
    op.execute("DROP TABLE IF EXISTS document_links CASCADE;")
    op.execute("DROP TABLE IF EXISTS ai_sparks CASCADE;")
    op.execute("DROP TABLE IF EXISTS media_assets CASCADE;")
    op.execute("DROP TABLE IF EXISTS capture_annotations CASCADE;")
    op.execute("DROP TABLE IF EXISTS captures CASCADE;")
    op.execute("DROP TABLE IF EXISTS reading_sessions CASCADE;")
    op.execute("DROP TABLE IF EXISTS devices CASCADE;")

    op.execute("DROP FUNCTION IF EXISTS bump_sync_version CASCADE;")
    op.execute("DROP SEQUENCE IF EXISTS global_sync_seq CASCADE;")

    op.execute("DROP TYPE IF EXISTS reminder_type_enum CASCADE;")
    op.execute("DROP TYPE IF EXISTS link_type_enum CASCADE;")
    op.execute("DROP TYPE IF EXISTS processing_status_enum CASCADE;")
    op.execute("DROP TYPE IF EXISTS capture_type_enum CASCADE;")
