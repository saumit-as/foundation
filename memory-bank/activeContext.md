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

## 3. Next Immediate Steps
Proceeding to **Task 03 (`tasks/03_AUTH_CLI_QR_PAIRING_AND_FAST_CAPTURE_API.md`)**:
- Implement Zero-Trust edge auth middleware (`app/core/security.py`).
- Implement `app/cli.py` (`register-device --qr`, `revoke-device`, `seed-persona`).
- Implement fast capture `<50ms` SLA endpoint (`POST /api/v1/capture`).
- Implement media streaming (`GET /api/v1/media/{id}/stream` with Range header support).
- Implement delta sync endpoint (`POST /api/v1/sync/delta`).

## 4. Active Decisions & Considerations
- **Persona Seeding:** Created `contracts/initial_persona.json` matching `contracts/persona.schema.json` so CLI persona bootstrapping (`app.cli seed-persona`) has immediate valid seed data.
- **Precision Invariant:** Host CPU execution requires `torch.float32` for `EmbeddingGemma 2`. Never allow `float16`.
- **Contract Synchronization:** `contracts/openapi.json` and Pydantic schemas must remain 1:1 synchronized at every step.

