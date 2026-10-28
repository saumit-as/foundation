# Active Context: Memoria v3

## 1. Current Work Focus
- Initial memory bank initialized from architectural specifications (`docs/00` to `docs/09`), API contracts (`contracts/openapi.json`, `contracts/persona.schema.json`), and task files (`tasks/00` to `tasks/10`).
- Master Task Index (`tasks/00_TASK_RUNNER_AND_INDEX.md`) is tracking 10 sequential implementation tasks.

## 2. Completed Tasks
- **Task 01 (`tasks/01_INFRA_POSTGRES_REDIS_AND_ENV.md`):** `[x] PASSED` (Docker environment, postgres, redis, ntfy).
- **Task 02 (`tasks/02_BACKEND_SCAFFOLD_ORM_AND_ALEMBIC.md`):** `[x] PASSED`
  - `/server` initialized with `uv` (`pyproject.toml`, `uv.lock`) using Python 3.12.
  - Core settings (`app/core/config.py`) and async database engine (`app/db/session.py`).
  - All 4 Enums (`CaptureTypeEnum`, `ProcessingStatusEnum`, `LinkTypeEnum`, `ReminderTypeEnum`) and 10 SQLModel tables implemented strictly matching `docs/02_DATABASE_AND_VECTOR_SCHEMA.md`.
  - Alembic async migration `0001_initial_schema.py` applied, creating extensions (`uuid-ossp`, `vector`, `pg_trgm`), tables, GIN indexes on `search_tsv` and tags, HNSW cosine index `VECTOR(768)` on `embeddings`, and `bump_sync_version()` triggers.
  - Deterministic Verification Gate passed cleanly with `TASK_02_SCHEMA_VERIFIED_OK`.

- **Task 03 (`tasks/03_AUTH_CLI_QR_PAIRING_AND_FAST_CAPTURE_API.md`):** `[x] PASSED`
  - Zero-Trust security dependency implemented in `app/core/security.py` verifying CF Access headers and Bearer API key against `devices`.
  - CLI implemented in `app/cli.py` supporting `register-device --qr`, `revoke-device`, and `seed-persona` with prompt-cache prefix generation (>= 4200 chars).
  - Pydantic v2 schemas in `app/schemas/capture.py` and `app/schemas/sync.py`.
  - Fast capture endpoints `POST /api/v1/capture` (<50ms SLA) and `POST /api/v1/capture/batch` with PostgreSQL `on_conflict_do_nothing` idempotent upserts.
  - Media upload `POST /api/v1/capture/{capture_id}/media` with streaming SHA-256 validation and HTTP Range streaming `GET /api/v1/media/{asset_id}` (`HTTP 206 Partial Content`).
  - Monotonic delta sync endpoint `GET /api/v1/sync/delta?since_version={int}&limit=200`.
  - Deterministic verification suite `tests/test_task_03_capture_sync.py` passed (5/5 tests in 0.96s).

## 3. Next Immediate Steps
Proceeding to **Task 04 (`tasks/04_EMBEDDING_GEMMA2_AND_HYBRID_SEARCH.md`)**:
- Implement `app/services/embedder.py` wrapping `google/embeddinggemma-2` (`bfloat16`/`float32`, 768d, Redis GPU mutex `lock:gpu_inference`).
- Asymmetric task prefixes (`SearchQuery`, document format).
- Reciprocal Rank Fusion (RRF 60) hybrid search endpoint `POST /api/v1/search`.

## 4. Active Decisions & Considerations
- **Persona Seeding:** Created `contracts/initial_persona.json` matching `contracts/persona.schema.json` so CLI persona bootstrapping (`app.cli seed-persona`) has immediate valid seed data.
- **Precision Invariant:** Host CPU execution requires `torch.float32` for `EmbeddingGemma 2`. Never allow `float16`.
- **Contract Synchronization:** `contracts/openapi.json` and Pydantic schemas must remain 1:1 synchronized at every step.

