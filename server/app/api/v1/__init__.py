"""API v1 router assembly."""

from fastapi import APIRouter

from app.api.v1.capture import router as capture_router
from app.api.v1.media import router as media_router
from app.api.v1.sync import router as sync_router

api_v1_router = APIRouter(prefix="/api/v1")
api_v1_router.include_router(capture_router, tags=["capture"])
api_v1_router.include_router(media_router, tags=["media"])
api_v1_router.include_router(sync_router, tags=["sync"])
