# 02_BACKEND_SCAFFOLD_ORM_AND_ALEMBIC.md
> **TASK 02: PYTHON `uv` PROJECT, SQLALCHEMY 2.0 / SQLMODEL TABLES, TRIGGERS & ALEMBIC MIGRATION**
> - **Prerequisites:** Task 01 `[x] PASSED` (`postgres` and `redis` containers running)
> - **Reference Spec:** [`docs/02_DATABASE_AND_VECTOR_SCHEMA.md`](../docs/02_DATABASE_AND_VECTOR_SCHEMA.md) and [`docs/00_AGENT_RULES_AND_MONOREPO.md`](../docs/00_AGENT_RULES_AND_MONOREPO.md)

---

## 1. Objective
Initialize `/server` managed strictly by `uv` (`Python >= 3.12`), configure `ruff` and `mypy`, define the async database session and all 10 PostgreSQL tables + 4 enums + `search_tsv` generated columns + `bump_sync_version()` triggers + `VECTOR(768)` HNSW index via SQLAlchemy 2.0 / SQLModel and Alembic, apply the migration to PostgreSQL, and run a deterministic schema verification script.

---

## 2. Exact Files to Create

1. `server/pyproject.toml`
2. `server/app/__init__.py`
3. `server/app/core/__init__.py`
4. `server/app/core/config.py`
5. `server/app/db/__init__.py`
6. `server/app/db/session.py`
7. `server/app/models/__init__.py`
8. `server/app/models/enums.py`
9. `server/app/models/tables.py`
10. `server/alembic.ini`
11. `server/alembic/env.py`
12. `server/alembic/script.py.mako`
13. `server/alembic/versions/0001_initial_schema.py`
14. `server/scripts/verify_task_02.py`

---

## 3. Step-by-Step Implementation Instructions

### Step 3.1: Create `server/pyproject.toml` and Lock Dependencies with `uv`
Define `pyproject.toml` requiring `python = ">=3.12"` and dependencies:
- `fastapi>=0.115.0`, `uvicorn[standard]>=0.32.0`, `python-multipart>=0.0.12`
- `pydantic>=2.9.0`, `pydantic-settings>=2.6.0`, `jsonschema>=4.23.0`
- `sqlalchemy[asyncio]>=2.0.36`, `sqlmodel>=0.0.22`, `asyncpg>=0.30.0`, `alembic>=1.14.0`, `pgvector>=0.3.6`
- `redis>=5.2.0`, `taskiq>=0.11.9`, `taskiq-redis>=1.0.2`
- `httpx>=0.27.2`, `uuid6>=2024.7.10`, `qrcode>=8.0`, `pillow>=11.0.0`, `numpy>=2.1.0`
- Dev dependencies: `pytest>=8.3.0`, `pytest-asyncio>=0.24.0`, `ruff>=0.7.0`, `mypy>=1.13.0`

Run `cd server && uv sync` to generate `uv.lock`.

### Step 3.2: Implement `server/app/core/config.py` and `server/app/db/session.py`
- Use `pydantic_settings.BaseSettings` reading from `../infra/.env` (or environment variables).
- Create `async_engine = create_async_engine(settings.DATABASE_URL, pool_pre_ping=True)` and `AsyncSessionLocal = async_sessionmaker(async_engine, class_=AsyncSession, expire_on_commit=False)`.

### Step 3.3: Implement Enums (`server/app/models/enums.py`) & Tables (`server/app/models/tables.py`)
Define all 4 PostgreSQL enums (`CaptureTypeEnum`, `ProcessingStatusEnum`, `LinkTypeEnum`, `ReminderTypeEnum`) and all 10 tables strictly matching `docs/02_DATABASE_AND_VECTOR_SCHEMA.md`:
1. `Device` (`devices`)
2. `ReadingSession` (`reading_sessions`)
3. `Capture` (`captures` — including `reading_session_id`, `page_range`, `annotations_concat`, `is_triage_reviewed`, `sync_version`)
4. `CaptureAnnotation` (`capture_annotations` — append-only marginalia)
5. `MediaAsset` (`media_assets` — including `page_order`, `soft_token_budget`)
6. `AiSpark` (`ai_sparks`)
7. `DocumentLink` (`document_links`)
8. `Embedding` (`embeddings` — `Vector(768)` from `pgvector.sqlalchemy`)
9. `PersonaSnapshot` (`persona_snapshots`)
10. `Reminder` (`reminders`)

### Step 3.4: Create Alembic Migration `server/alembic/versions/0001_initial_schema.py`
Write the complete, deterministic DDL migration in `0001_initial_schema.py` executing the exact SQL from `docs/02_DATABASE_AND_VECTOR_SCHEMA.md` Section 2 (2.1 through 2.5):
- Creates extensions `uuid-ossp`, `vector`, `pg_trgm`.
- Creates all 4 enums and all 10 tables.
- Creates the `STORED` generated `search_tsv` columns and `GIN` indexes on `captures` and `ai_sparks`.
- Creates the HNSW cosine index `idx_embeddings_hnsw_cosine ON embeddings USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 128)`.
- Creates `global_sync_seq`, `bump_sync_version()`, and attaches the `BEFORE INSERT OR UPDATE` triggers on `captures`, `ai_sparks`, `reminders`, `reading_sessions`, and `capture_annotations`.

### Step 3.5: Create Verification Script `server/scripts/verify_task_02.py`
Write a Python script that connects to PostgreSQL using `asyncpg` / `SQLAlchemy` and asserts:
1. All 10 tables exist in `information_schema.tables`.
2. Index `idx_embeddings_hnsw_cosine` exists in `pg_indexes`.
3. Inserting a dummy `Capture` row automatically assigns `sync_version >= 1` via `trg_captures_sync_version` and populates `search_tsv`, then rolls back cleanly.
4. Prints `TASK_02_SCHEMA_VERIFIED_OK` and exits with code `0`.

---

## 4. Deterministic Verification Gate (`PASS / FAIL`)

Run the following commands inside `/server`. **All 4 checks must exit with code `0`:**

```powershell
cd server
uv run ruff check .
uv run mypy app
uv run alembic upgrade head
uv run python scripts/verify_task_02.py
```
- **Expected Output on Final Command:** `TASK_02_SCHEMA_VERIFIED_OK`

Once all 4 commands exit `0`, mark **Task 02** as `[x] PASSED` in `tasks/00_TASK_RUNNER_AND_INDEX.md`.
