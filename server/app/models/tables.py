import uuid
from datetime import datetime
from typing import Any

from pgvector.sqlalchemy import Vector
from sqlalchemy import (
    CHAR,
    BigInteger,
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import ARRAY, JSONB, TSVECTOR
from sqlmodel import Field, Relationship, SQLModel

from app.models.enums import (
    CaptureTypeEnum,
    LinkTypeEnum,
    ProcessingStatusEnum,
    ReminderTypeEnum,
)


class Device(SQLModel, table=True):
    __tablename__ = "devices"

    id: uuid.UUID = Field(
        default_factory=uuid.uuid4,
        primary_key=True,
        sa_column_kwargs={"server_default": text("uuid_generate_v4()")},
    )
    device_name: str = Field(sa_column=Column(String(120), nullable=False))
    device_type: str = Field(sa_column=Column(String(32), nullable=False))
    api_key_hash: str = Field(sa_column=Column(String(255), nullable=False, unique=True))
    last_sync_at: datetime | None = Field(default=None, sa_column=Column(DateTime(timezone=True)))
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False, server_default=text("NOW()")),
    )
    is_revoked: bool = Field(default=False, nullable=False)


class ReadingSession(SQLModel, table=True):
    __tablename__ = "reading_sessions"

    id: uuid.UUID = Field(primary_key=True)
    source_title: str = Field(sa_column=Column(String(512), nullable=False))
    author: str | None = Field(default=None, sa_column=Column(String(255)))
    isbn_or_url: str | None = Field(default=None, sa_column=Column(Text))
    default_tags: list[str] = Field(
        default_factory=lambda: ["book"],
        sa_column=Column(ARRAY(String), nullable=False, server_default=text("'{book}'")),
    )
    is_active: bool = Field(default=True, nullable=False)
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False, server_default=text("NOW()")),
    )
    updated_at: datetime = Field(
        default_factory=datetime.utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False, server_default=text("NOW()")),
    )
    sync_version: int = Field(
        default=1,
        sa_column=Column(BigInteger, nullable=False, server_default=text("1")),
    )


class Capture(SQLModel, table=True):
    __tablename__ = "captures"

    id: uuid.UUID = Field(primary_key=True)
    device_id: uuid.UUID | None = Field(
        default=None,
        sa_column=Column(ForeignKey("devices.id", ondelete="SET NULL"), nullable=True),
    )
    reading_session_id: uuid.UUID | None = Field(
        default=None,
        sa_column=Column(ForeignKey("reading_sessions.id", ondelete="SET NULL"), nullable=True),
    )
    capture_type: CaptureTypeEnum = Field(nullable=False)
    processing_status: ProcessingStatusEnum = Field(
        default=ProcessingStatusEnum.QUEUED,
        nullable=False,
    )

    # Immutable User Input
    title: str | None = Field(default=None, sa_column=Column(String(512)))
    raw_text: str | None = Field(default=None, sa_column=Column(Text))
    source_url: str | None = Field(default=None, sa_column=Column(Text))
    page_range: str | None = Field(default=None, sa_column=Column(String(64)))
    user_tags: list[str] = Field(
        default_factory=list,
        sa_column=Column(ARRAY(String), nullable=False, server_default=text("'{}'")),
    )

    # Server-Extracted Metadata
    canonical_url: str | None = Field(default=None, sa_column=Column(Text))
    domain: str | None = Field(default=None, sa_column=Column(String(255)))
    extracted_title: str | None = Field(default=None, sa_column=Column(String(512)))
    extracted_markdown: str | None = Field(default=None, sa_column=Column(Text))
    ocr_text: str | None = Field(default=None, sa_column=Column(Text))
    transcript_text: str | None = Field(default=None, sa_column=Column(Text))
    annotations_concat: str = Field(
        default="",
        sa_column=Column(Text, nullable=False, server_default=text("''")),
    )
    auto_tags: list[str] = Field(
        default_factory=list,
        sa_column=Column(ARRAY(String), nullable=False, server_default=text("'{}'")),
    )
    extraction_metadata: dict[str, Any] = Field(
        default_factory=dict,
        sa_column=Column(JSONB, nullable=False, server_default=text("'{}'::jsonb")),
    )

    # TSVector Full-Text Search Column (Generated always as stored in DDL)
    search_tsv: Any = Field(default=None, sa_column=Column(TSVECTOR))

    # Sync, Triage & Timestamps
    captured_at: datetime = Field(sa_column=Column(DateTime(timezone=True), nullable=False))
    updated_at: datetime = Field(
        default_factory=datetime.utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False, server_default=text("NOW()")),
    )
    is_triage_reviewed: bool = Field(default=False, nullable=False)
    is_archived: bool = Field(default=False, nullable=False)
    is_deleted: bool = Field(default=False, nullable=False)
    sync_version: int = Field(
        default=1,
        sa_column=Column(BigInteger, nullable=False, server_default=text("1")),
    )

    # Relationships
    annotations: list["CaptureAnnotation"] = Relationship(
        back_populates="capture",
        cascade_delete=True,
    )
    media_assets: list["MediaAsset"] = Relationship(
        back_populates="capture",
        cascade_delete=True,
    )


class CaptureAnnotation(SQLModel, table=True):
    __tablename__ = "capture_annotations"

    id: uuid.UUID = Field(primary_key=True)
    capture_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("captures.id", ondelete="CASCADE"), nullable=False)
    )
    content: str = Field(sa_column=Column(Text, nullable=False))
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False, server_default=text("NOW()")),
    )
    sync_version: int = Field(
        default=1,
        sa_column=Column(BigInteger, nullable=False, server_default=text("1")),
    )

    capture: Capture | None = Relationship(back_populates="annotations")


class MediaAsset(SQLModel, table=True):
    __tablename__ = "media_assets"

    id: uuid.UUID = Field(primary_key=True)
    capture_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("captures.id", ondelete="CASCADE"), nullable=False)
    )
    media_kind: str = Field(sa_column=Column(String(32), nullable=False))
    page_order: int = Field(
        default=0, sa_column=Column(Integer, nullable=False, server_default=text("0"))
    )
    local_rel_path: str = Field(sa_column=Column(Text, nullable=False))
    mime_type: str = Field(sa_column=Column(String(127), nullable=False))
    file_size_bytes: int = Field(sa_column=Column(BigInteger, nullable=False))
    sha256_checksum: str = Field(sa_column=Column(CHAR(64), nullable=False))
    duration_seconds: float | None = Field(default=None, sa_column=Column(Float))
    width_px: int | None = Field(default=None, sa_column=Column(Integer))
    height_px: int | None = Field(default=None, sa_column=Column(Integer))
    soft_token_budget: int | None = Field(
        default=280,
        sa_column=Column(Integer, server_default=text("280")),
    )
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False, server_default=text("NOW()")),
    )

    capture: Capture | None = Relationship(back_populates="media_assets")


class AiSpark(SQLModel, table=True):
    __tablename__ = "ai_sparks"

    id: uuid.UUID = Field(
        default_factory=uuid.uuid4,
        primary_key=True,
        sa_column_kwargs={"server_default": text("uuid_generate_v4()")},
    )
    title: str = Field(sa_column=Column(String(512), nullable=False))
    spark_markdown: str = Field(sa_column=Column(Text, nullable=False))
    spark_rationale: str | None = Field(default=None, sa_column=Column(Text))
    related_project: str | None = Field(default=None, sa_column=Column(String(255)))
    tags: list[str] = Field(
        default_factory=list,
        sa_column=Column(ARRAY(String), nullable=False, server_default=text("'{}'")),
    )
    model_id: str = Field(
        default="gpt-6-luna",
        sa_column=Column(String(64), nullable=False, server_default=text("'gpt-6-luna'")),
    )
    prompt_cache_hit: bool = Field(
        default=True,
        sa_column=Column(nullable=False, server_default=text("TRUE")),
    )
    search_tsv: Any = Field(default=None, sa_column=Column(TSVECTOR))
    is_read: bool = Field(default=False, nullable=False)
    is_pinned: bool = Field(default=False, nullable=False)
    is_dismissed: bool = Field(default=False, nullable=False)
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False, server_default=text("NOW()")),
    )
    updated_at: datetime = Field(
        default_factory=datetime.utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False, server_default=text("NOW()")),
    )
    sync_version: int = Field(
        default=1,
        sa_column=Column(BigInteger, nullable=False, server_default=text("1")),
    )


class DocumentLink(SQLModel, table=True):
    __tablename__ = "document_links"
    __table_args__ = (UniqueConstraint("source_id", "target_id", "link_type", name="uq_doc_links"),)

    id: uuid.UUID = Field(
        default_factory=uuid.uuid4,
        primary_key=True,
        sa_column_kwargs={"server_default": text("uuid_generate_v4()")},
    )
    source_id: uuid.UUID = Field(nullable=False)
    source_table: str = Field(sa_column=Column(String(32), nullable=False))
    target_id: uuid.UUID = Field(nullable=False)
    target_table: str = Field(sa_column=Column(String(32), nullable=False))
    link_type: LinkTypeEnum = Field(nullable=False)
    similarity_score: float | None = Field(default=None, sa_column=Column(Float))
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False, server_default=text("NOW()")),
    )


class Embedding(SQLModel, table=True):
    __tablename__ = "embeddings"
    __table_args__ = (
        UniqueConstraint("owner_id", "owner_table", "chunk_index", name="uq_embeddings_chunk"),
    )

    id: uuid.UUID = Field(
        default_factory=uuid.uuid4,
        primary_key=True,
        sa_column_kwargs={"server_default": text("uuid_generate_v4()")},
    )
    owner_id: uuid.UUID = Field(nullable=False)
    owner_table: str = Field(sa_column=Column(String(32), nullable=False))
    chunk_index: int = Field(
        default=0, sa_column=Column(Integer, nullable=False, server_default=text("0"))
    )
    modality_composition: str = Field(sa_column=Column(String(64), nullable=False))
    token_count: int = Field(sa_column=Column(Integer, nullable=False))
    chunk_preview_text: str | None = Field(default=None, sa_column=Column(Text))
    embedding: list[float] = Field(sa_column=Column(Vector(768), nullable=False))
    model_version: str = Field(
        default="google/embeddinggemma-2",
        sa_column=Column(
            String(64), nullable=False, server_default=text("'google/embeddinggemma-2'")
        ),
    )
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False, server_default=text("NOW()")),
    )


class PersonaSnapshot(SQLModel, table=True):
    __tablename__ = "persona_snapshots"

    id: int | None = Field(default=None, primary_key=True)
    version_number: int = Field(sa_column=Column(Integer, nullable=False, unique=True))
    is_current: bool = Field(default=True, nullable=False)
    persona_json: dict[str, Any] = Field(sa_column=Column(JSONB, nullable=False))
    cached_prompt_prefix: str = Field(sa_column=Column(Text, nullable=False))
    summary_diff: str | None = Field(default=None, sa_column=Column(Text))
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False, server_default=text("NOW()")),
    )


class Reminder(SQLModel, table=True):
    __tablename__ = "reminders"

    id: uuid.UUID = Field(
        default_factory=uuid.uuid4,
        primary_key=True,
        sa_column_kwargs={"server_default": text("uuid_generate_v4()")},
    )
    target_id: uuid.UUID = Field(nullable=False)
    target_table: str = Field(sa_column=Column(String(32), nullable=False))
    reminder_type: ReminderTypeEnum = Field(nullable=False)
    title: str = Field(sa_column=Column(String(255), nullable=False))
    message: str = Field(sa_column=Column(Text, nullable=False))
    deep_link_uri: str = Field(sa_column=Column(Text, nullable=False))
    scheduled_for: datetime = Field(sa_column=Column(DateTime(timezone=True), nullable=False))
    dispatched_at: datetime | None = Field(default=None, sa_column=Column(DateTime(timezone=True)))
    ntfy_message_id: str | None = Field(default=None, sa_column=Column(String(128)))
    is_acknowledged: bool = Field(default=False, nullable=False)
    snoozed_until: datetime | None = Field(default=None, sa_column=Column(DateTime(timezone=True)))
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False, server_default=text("NOW()")),
    )
    sync_version: int = Field(
        default=1,
        sa_column=Column(BigInteger, nullable=False, server_default=text("1")),
    )
