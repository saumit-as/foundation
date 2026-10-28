from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import api_v1_router
from app.core.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    # Ensure media directory exists
    settings.MEDIA_ROOT.mkdir(parents=True, exist_ok=True)
    yield


app = FastAPI(
    title="Memoria Server API",
    version="3.1.0",
    description="Personal Context, Scratchpad, and Multimodal Ingestion Engine",
    lifespan=lifespan,
)

# CORS Middleware (allowed for local development and extension)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_v1_router)


@app.get("/health", tags=["system"])
async def health_check() -> dict[str, str]:
    return {"status": "ok", "service": "memoria-server"}
