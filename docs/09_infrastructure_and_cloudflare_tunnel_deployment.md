# 09_INFRA_AND_TUNNEL_DEPLOYMENT.md
> **HOME SERVER DOCKER COMPOSE, GPU PASSTHROUGH & CLOUDFLARE ZERO TRUST SPEC**
> This document defines the complete production deployment on the home server (`/infra`), including GPU passthrough for `google/embeddinggemma-2`, persistent storage volumes, `ntfy` broker configuration, and Cloudflare Tunnel (`cloudflared`) Zero Trust Service Token hardening.

---

## 1. Home Server Directory & Volume Layout

```text
/infra/
├── docker-compose.yml
├── .env                             # Never committed to git (copied from .env.example)
├── .env.example
├── postgres/
│   └── init.sql                     # Enables vector, uuid-ossp, pg_trgm extensions
└── ntfy/
    └── server.yml                   # Self-hosted ntfy configuration
```

Host bind-mount paths (or named volumes):
- `./data/postgres`: PostgreSQL 16 + `pgvector` data directory
- `./data/media`: Raw scraped Reels, audio tracks, PDFs, and book scans (never leaves home server)
- `./data/hf_cache`: HuggingFace model cache (`google/embeddinggemma-2` + `faster-whisper` weights)
- `./data/ntfy`: Persistent SQLite message cache for `ntfy`
- `./data/backups`: Automated nightly `pg_dump` compressed archives + exported Markdown vault snapshots (retained 30 days)

---

## 2. Production `docker-compose.yml`

```yaml
services:
  postgres:
    image: pgvector/pgvector:pg16
    container_name: scratchpad-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-scratchpad}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?err}
      POSTGRES_DB: ${POSTGRES_DB:-scratchpad_db}
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
      - ./postgres/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-scratchpad} -d ${POSTGRES_DB:-scratchpad_db}"]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - internal_net

  redis:
    image: redis:7-alpine
    container_name: scratchpad-redis
    restart: unless-stopped
    command: ["redis-server", "--appendonly", "yes"]
    volumes:
      - ./data/redis:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5
    networks:
      - internal_net

  server-api:
    build:
      context: ../server
      dockerfile: Dockerfile
    container_name: scratchpad-api
    restart: unless-stopped
    # Single async worker process so EmbeddingGemma 2 is loaded only once in server-api
    # and coordinates GPU execution with server-worker via Redis lock:gpu_inference
    command: ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
    env_file: .env
    volumes:
      - ./data/media:/data/media
      - ./data/hf_cache:/root/.cache/huggingface
      - ./data/backups:/data/backups
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    networks:
      - internal_net

  server-worker:
    build:
      context: ../server
      dockerfile: Dockerfile
    container_name: scratchpad-worker
    restart: unless-stopped
    command: ["uv", "run", "taskiq", "worker", "app.workers.tasks:broker", "--workers", "1"]
    env_file: .env
    volumes:
      - ./data/media:/data/media
      - ./data/hf_cache:/root/.cache/huggingface
      - ./data/backups:/data/backups
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    networks:
      - internal_net

  ntfy:
    image: binwiederhier/ntfy:latest
    container_name: scratchpad-ntfy
    restart: unless-stopped
    command: ["serve"]
    environment:
      TZ: ${TZ:-Asia/Kolkata}
    volumes:
      - ./ntfy/server.yml:/etc/ntfy/server.yml:ro
      - ./data/ntfy:/var/cache/ntfy
    networks:
      - internal_net

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: scratchpad-tunnel
    restart: unless-stopped
    command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TUNNEL_TOKEN:?err}
    depends_on:
      - server-api
      - ntfy
    networks:
      - internal_net

networks:
  internal_net:
    driver: bridge
```

---

## 3. Environment Configuration (`/infra/.env.example`)

```ini
# Database & Redis
POSTGRES_USER=scratchpad
POSTGRES_PASSWORD=generate_strong_32_char_password_here
POSTGRES_DB=scratchpad_db
DATABASE_URL=postgresql+asyncpg://scratchpad:generate_strong_32_char_password_here@postgres:5432/scratchpad_db
REDIS_URL=redis://redis:6379/0

# Local EmbeddingGemma 2 Configuration
EMBEDDING_MODEL_ID=google/embeddinggemma-2
EMBEDDING_DEVICE=cuda
HF_TOKEN=hf_your_read_token_for_gated_gemma_weights

# OpenAI Cloud Synthesis (GPT-6 Luna)
OPENAI_API_KEY=sk-proj-your_openai_key
OPENAI_MODEL_ID=gpt-6-luna

# Self-Hosted ntfy Broker
NTFY_INTERNAL_URL=http://ntfy:80
NTFY_PUBLIC_URL=https://api.yourdomain.com/ntfy
NTFY_TOPIC=scratchpad_alerts
NTFY_ACCESS_TOKEN=tk_your_generated_ntfy_bearer_token

# Cloudflare Zero Trust Tunnel
CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoi...
```

---

## 4. Self-Hosted `ntfy` Configuration (`/infra/ntfy/server.yml`)

```yaml
base-url: "https://api.yourdomain.com/ntfy"
listen-http: ":80"
cache-file: "/var/cache/ntfy/cache.db"
cache-duration: "168h" # Retain notifications for 7 days for offline Android sync
auth-file: "/var/cache/ntfy/user.db"
auth-default-access: "deny-all"
behind-proxy: true
enable-login: true
```

---

## 5. Cloudflare Zero Trust Hardening Checklist

1. **Tunnel Public Hostname Routing:**
   - Route `https://api.yourdomain.com/ntfy*` -> `http://ntfy:80` (strip `/ntfy` prefix or match base-url).
   - Route `https://api.yourdomain.com/*` -> `http://server-api:8000`.
2. **Cloudflare Access Application Policy:**
   - Create a Self-Hosted Application in Cloudflare Zero Trust covering `api.yourdomain.com`.
   - Set **Action = Service Auth** (non-identity policy) requiring your generated **Service Token** (`CF-Access-Client-Id` & `CF-Access-Client-Secret`).
   - Add a **WAF Rate Limiting Rule** at the Cloudflare edge: max `120 requests / minute` per IP to prevent brute-force or runaway background loops from hitting your home server GPU or OpenAI `gpt-6-luna` quota.

---

## 6. Automated Nightly Backup & Markdown Vault Snapshot (`03:30 AM`)

To ensure zero data loss and full offline portability outside PostgreSQL:
1. A scheduled Taskiq cron job (`job_nightly_backup_and_export` at `03:30 AM` right after Persona Reflection) runs inside `server-worker`:
   - Executes `pg_dump -Fc scratchpad_db > /data/backups/db/scratchpad_$(date +%F).dump`.
   - Exports all `captures` (with `capture_annotations`) and `ai_sparks` as clean, human-readable Markdown files with YAML frontmatter and `[[wiki-links]]` into `/data/backups/vault_mirror/`.
   - Prunes daily `.dump` archives older than 30 days.

---

## 7. Recommended Build Order for Your Coding Agent

When instructing your coding agent to build the repository, execute in these 5 sequential milestones:
1. **Milestone 1 (Infra & DB):** Spin up `postgres` + `redis` + `Alembic` migrations from `02_DATABASE_AND_VECTOR_SCHEMA.md` and verify `VECTOR(768)` HNSW index creation.
2. **Milestone 2 (Core API & Auth):** Implement FastAPI `/api/v1/capture`, `/api/v1/sync/delta`, and Bearer device auth from `03_API_AND_SYNC_CONTRACT.md`.
3. **Milestone 3 (Local Multimodal Engine):** Implement `embedder.py` (`EmbeddingGemma 2` in `bfloat16`/`float32`) and `scraper.py` (`yt-dlp`, `PaddleOCR`, `faster-whisper`) from `04` and `05`.
4. **Milestone 4 (Cloud Spark & Push Engine):** Implement `luna_agent.py` (`gpt-6-luna` with cached `persona.json` prefix) and `notifier.py` (`ntfy`) from `06` and `07`.
5. **Milestone 5 (Clients):** Build the WXT Browser Extension (`/extension`) and Flutter Multi-Device App (`/app_client`) from `08_CLIENT_AND_EXTENSION_SPECS.md`.