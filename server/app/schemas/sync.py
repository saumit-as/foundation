from typing import Any

from pydantic import BaseModel, ConfigDict


class DeltaSyncResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    since_version: int
    current_max_sync_version: int
    has_more: bool = False
    captures: list[dict[str, Any]]
    reading_sessions: list[dict[str, Any]]
    ai_sparks: list[dict[str, Any]]
    reminders: list[dict[str, Any]]
