from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment or infra/.env."""

    model_config = SettingsConfigDict(
        env_file=(
            Path(__file__).resolve().parent.parent.parent.parent / "infra" / ".env",
            Path(__file__).resolve().parent.parent.parent / ".env",
        ),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Database & Redis
    POSTGRES_USER: str = "scratchpad"
    POSTGRES_PASSWORD: str = "scratchpad_local_dev_pw_32chars"
    POSTGRES_DB: str = "scratchpad_db"
    DATABASE_URL: str = "postgresql+asyncpg://scratchpad:scratchpad_local_dev_pw_32chars@postgres:5432/scratchpad_db"
    REDIS_URL: str = "redis://redis:6379/0"

    # Multimodal Embedding Configuration
    EMBEDDING_MODEL_ID: str = "google/embeddinggemma-2"
    EMBEDDING_DEVICE: str = "cpu"
    HF_TOKEN: str = ""

    # Cloud LLM Configuration
    OPENAI_API_KEY: str = ""
    OPENAI_MODEL_ID: str = "gpt-6-luna"

    # Push Notification Broker
    NTFY_INTERNAL_URL: str = "http://ntfy:80"
    NTFY_PUBLIC_URL: str = "https://ntfy.yourdomain.com"
    NTFY_TOPIC: str = "scratchpad_alerts"
    NTFY_ACCESS_TOKEN: str = ""

    # Cloudflare Zero Trust Tunnel
    CLOUDFLARE_TUNNEL_TOKEN: str = ""


settings = Settings()
