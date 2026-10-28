"""API v1 router assembly."""

from fastapi import APIRouter

from app.api.v1.capture import router as capture_router
from app.api.v1.export import router as export_router
from app.api.v1.media import router as media_router
from app.api.v1.persona import router as persona_router
from app.api.v1.reading_sessions import router as reading_router
from app.api.v1.reminders import router as reminders_router
from app.api.v1.scraper import router as scraper_router
from app.api.v1.search import router as search_router
from app.api.v1.sparks import router as sparks_router
from app.api.v1.sync import router as sync_router
from app.api.v1.triage import router as triage_router

api_v1_router = APIRouter(prefix="/api/v1")
api_v1_router.include_router(capture_router, tags=["capture"])
api_v1_router.include_router(export_router, tags=["export"])
api_v1_router.include_router(media_router, tags=["media"])
api_v1_router.include_router(persona_router, tags=["persona"])
api_v1_router.include_router(reading_router, tags=["reading-sessions"])
api_v1_router.include_router(reminders_router, tags=["reminders"])
api_v1_router.include_router(scraper_router, tags=["scraper"])
api_v1_router.include_router(search_router, tags=["search"])
api_v1_router.include_router(sparks_router, tags=["sparks"])
api_v1_router.include_router(sync_router, tags=["sync"])
api_v1_router.include_router(triage_router, tags=["triage"])
