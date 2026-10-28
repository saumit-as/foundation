# Active Context: Memoria v3

## 1. Current Work Focus
- Initial memory bank initialized from architectural specifications (`docs/00` to `docs/09`), API contracts (`contracts/openapi.json`, `contracts/persona.schema.json`), and task files (`tasks/00` to `tasks/10`).
- Master Task Index (`tasks/00_TASK_RUNNER_AND_INDEX.md`) is tracking 10 sequential implementation tasks.

## 2. Completed Task: Task 01 (`tasks/01_INFRA_POSTGRES_REDIS_AND_ENV.md`)
- **Status:** `[x] PASSED`
- **Accomplishments:**
  - Dedicated LXC container `foundation` (VMID 102, Debian 12 Bookworm, 4 cores, 4GB RAM, 32GB disk, IP `192.168.88.102/24`, `nesting=1,keyctl=1`) created and started.
  - Docker CE 29.9.2 and Docker Compose v5.6.1 installed with native overlayfs storage driver.
  - `infra/docker-compose.yml`, `infra/postgres/init.sql`, `infra/ntfy/server.yml`, `infra/backup/backup.sh`, `infra/.env` created and configured.
  - Stateful services `postgres`, `redis`, and `ntfy` started and verified healthy.
  - Deterministic Verification Gate passed:
    - `count(*) FROM pg_extension WHERE extname IN ('uuid-ossp', 'vector', 'pg_trgm')` returned `3`.
    - `redis-cli ping` returned `PONG`.
    - `ntfy` health endpoint returned `{"healthy":true,"role":"active"}`.

## 3. Next Immediate Steps
1. User provides/configures local environment (`.env`) and confirms Docker availability.
2. Verify Task 01 containers exit code `0`.
3. Proceed to **Task 02 (`tasks/02_BACKEND_SCAFFOLD_ORM_AND_ALEMBIC.md`)**:
   - Initialize `/server` with `uv` (`pyproject.toml`).
   - Define the 10 SQLAlchemy 2.0 / SQLModel tables matching `02_DATABASE_AND_VECTOR_SCHEMA.md`.
   - Setup Alembic async migrations, create initial migration with `VECTOR(768)` HNSW index, verify with `scripts/verify_task_02.py`.

## 4. Active Decisions & Considerations
- **Persona Seeding:** Created `contracts/initial_persona.json` matching `contracts/persona.schema.json` so CLI persona bootstrapping (`app.cli seed-persona`) has immediate valid seed data.
- **Precision Invariant:** Host CPU execution requires `torch.float32` for `EmbeddingGemma 2`. Never allow `float16`.
- **Contract Synchronization:** `contracts/openapi.json` and Pydantic schemas must remain 1:1 synchronized at every step.

