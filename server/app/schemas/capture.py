import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import CaptureTypeEnum, ProcessingStatusEnum


class CaptureCreateRequest(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    reading_session_id: uuid.UUID | None = None
    capture_type: CaptureTypeEnum
    title: str | None = Field(default=None, max_length=512)
    raw_text: str | None = None
    source_url: str | None = None
    page_range: str | None = Field(default=None, max_length=64)
    user_tags: list[str] = Field(default_factory=list)
    captured_at: datetime
    dom_fallback_markdown: str | None = None


class CaptureAcceptedResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    status: str = "ACCEPTED"
    id: uuid.UUID
    processing_status: ProcessingStatusEnum = ProcessingStatusEnum.QUEUED
    sync_version: int


class CaptureBatchRequest(BaseModel):
    captures: list[CaptureCreateRequest] = Field(min_length=1, max_length=50)


class CaptureBatchResponse(BaseModel):
    status: str = "ACCEPTED"
    processed_count: int
    accepted_ids: list[uuid.UUID]
    max_sync_version: int


class MediaUploadResponse(BaseModel):
    status: str = "CREATED"
    asset_id: uuid.UUID
    capture_id: uuid.UUID
    local_rel_path: str
    file_size_bytes: int
    sha256_checksum: str
    mime_type: str


class CaptureResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    device_id: uuid.UUID | None = None
    reading_session_id: uuid.UUID | None = None
    capture_type: CaptureTypeEnum
    processing_status: ProcessingStatusEnum
    title: str | None = None
    raw_text: str | None = None
    source_url: str | None = None
    page_range: str | None = None
    user_tags: list[str] = Field(default_factory=list)
    extracted_title: str | None = None
    extracted_markdown: str | None = None
    ocr_text: str | None = None
    transcript_text: str | None = None
    sync_version: int
    captured_at: datetime

