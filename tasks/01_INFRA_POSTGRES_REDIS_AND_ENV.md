# 01_INFRA_POSTGRES_REDIS_AND_ENV.md
> **TASK 01: DOCKER INFRASTRUCTURE, VOLUMES, EXTENSIONS & ENVIRONMENT SETUP**
> - **Prerequisites:** None (First task)
> - **Reference Spec:** [`docs/09_infrastructure_and_cloudflare_tunnel_deployment.md`](../docs/09_infrastructure_and_cloudflare_tunnel_deployment.md) and [`docs/02_DATABASE_AND_VECTOR_SCHEMA.md`](../docs/02_DATABASE_AND_VECTOR_SCHEMA.md)

---

## 1. Objective
Create the `/infra` directory containing the production `docker-compose.yml`, PostgreSQL initialization script (`init.sql`), self-hosted `ntfy` configuration (`server.yml`), automated nightly backup script (`backup.sh`), and `.env.example`. Spin up the core stateful services (`postgres`, `redis`, `ntfy`) and verify all required PostgreSQL extensions (`vector`, `uuid-ossp`, `pg_trgm`).

---

## 2. Exact Files to Create

1. `infra/postgres/init.sql`
2. `infra/ntfy/server.yml`
3. `infra/backup/backup.sh`
4. `infra/.env.example`
5. `infra/docker-compose.yml`

---

## 3. Step-by-Step Implementation Instructions

### Step 3.1: Create `infra/postgres/init.sql`
Write the exact SQL required to enable `uuid-ossp`, `vector` (`pgvector`), and `pg_trgm` on container initialization:
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
```

### Step 3.2: Create `infra/ntfy/server.yml`
Write the self-hosted `ntfy` configuration exactly matching `docs/09_infrastructure_and_cloudflare_tunnel_deployment.md`:
```yaml
base-url: "https://api.yourdomain.com/ntfy"
listen-http: ":80"
cache-file: "/var/cache/ntfy/cache.db"
cache-duration: "168h"
auth-file: "/var/cache/ntfy/user.db"
auth-default-access: "read-write"
behind-proxy: true
enable-login: true
```
*(Note: `auth-default-access` is set to `read-write` on the internal Docker bridge for initial local verification and locked down to `deny-all` with a token in Task 07).*

### Step 3.3: Create `infra/backup/backup.sh`
Create a POSIX shell script that runs `pg_dump -Fc` into `/data/backups/db/` and prunes dumps older than 30 days:
```sh
#!/bin/sh
set -e
BACKUP_DIR="/data/backups/db"
mkdir -p "$BACKUP_DIR"
STAMP=$(date +%F_%H%M%S)
PGPASSWORD="${POSTGRES_PASSWORD}" pg_dump -h postgres -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -Fc > "${BACKUP_DIR}/scratchpad_${STAMP}.dump"
find "$BACKUP_DIR" -type f -name "*.dump" -mtime +30 -delete
echo "Backup completed: ${BACKUP_DIR}/scratchpad_${STAMP}.dump"
```

### Step 3.4: Create `infra/.env.example` and `infra/.env`
Copy the environment template from `docs/09_infrastructure_and_cloudflare_tunnel_deployment.md` Section 3 into `infra/.env.example`. If `infra/.env` does not exist yet, copy `infra/.env.example` to `infra/.env` with safe local defaults for `POSTGRES_USER=scratchpad`, `POSTGRES_PASSWORD=scratchpad_local_dev_pw_32chars`, `POSTGRES_DB=scratchpad_db`, and `DATABASE_URL=postgresql+asyncpg://scratchpad:scratchpad_local_dev_pw_32chars@localhost:5432/scratchpad_db`.

### Step 3.5: Create `infra/docker-compose.yml`
Write `infra/docker-compose.yml` from `docs/09_infrastructure_and_cloudflare_tunnel_deployment.md` Section 2, exposing port `5432:5432` on `postgres`, `6379:6379` on `redis`, and `8085:80` on `ntfy` bound to `127.0.0.1` (`127.0.0.1:5432:5432`, `127.0.0.1:6379:6379`, `127.0.0.1:8085:80`) so host-based CLI migrations and tests in Tasks 02–06 can connect directly to the containers while keeping them closed to external LAN/WAN interfaces.

---

## 4. `[USER INTERVENTION REQUIRED]` Checkpoint

Before starting the containers, check if Docker Desktop / Docker Engine is running and whether an NVIDIA GPU is present (`nvidia-smi`). If you need the user to provide their actual API keys or confirm CPU vs. GPU mode, pause and display:

```text
[USER INTERVENTION REQUIRED — TASK 01]
1. Please ensure Docker Desktop / Docker daemon is running.
2. Confirm whether this machine will run EmbeddingGemma 2 on NVIDIA GPU (`EMBEDDING_DEVICE=cuda`) or CPU (`EMBEDDING_DEVICE=cpu`).
3. Update `infra/.env` with your:
   - `HF_TOKEN` (HuggingFace token with access to google/embeddinggemma-2)
   - `OPENAI_API_KEY` (for gpt-6-luna; can be left as placeholder until Task 06)
Reply "continue" once Docker is running and `infra/.env` is updated.
```

---

## 5. Deterministic Verification Gate (`PASS / FAIL`)

Run the following commands in order. **All 3 checks must exit with code `0`:**

### Check 1: Start Stateful Containers
```powershell
docker compose -f infra/docker-compose.yml up -d postgres redis ntfy
```

### Check 2: Verify PostgreSQL Extensions (`uuid-ossp`, `vector`, `pg_trgm`)
```powershell
docker compose -f infra/docker-compose.yml exec -T postgres psql -U scratchpad -d scratchpad_db -tAc "SELECT count(*) FROM pg_extension WHERE extname IN ('uuid-ossp', 'vector', 'pg_trgm');"
```
- **Expected Output:** `3` (exact string `3`).

### Check 3: Verify Redis Ping
```powershell
docker compose -f infra/docker-compose.yml exec -T redis redis-cli ping
```
- **Expected Output:** `PONG`.

Once Checks 1, 2, and 3 succeed, mark **Task 01** as `[x] PASSED` in `tasks/00_TASK_RUNNER_AND_INDEX.md`.
