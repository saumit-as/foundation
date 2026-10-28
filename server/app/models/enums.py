from enum import StrEnum


class CaptureTypeEnum(StrEnum):
    text_note = "text_note"
    article_url = "article_url"
    pdf_document = "pdf_document"
    video_reel = "video_reel"
    image_upload = "image_upload"
    book_scan = "book_scan"
    audio_memo = "audio_memo"


class ProcessingStatusEnum(StrEnum):
    QUEUED = "QUEUED"
    EXTRACTING_MEDIA = "EXTRACTING_MEDIA"
    EXTRACTION_PARTIAL = "EXTRACTION_PARTIAL"
    EMBEDDING = "EMBEDDING"
    INDEXED = "INDEXED"
    SPARK_EVALUATED = "SPARK_EVALUATED"
    FAILED_RETRYABLE = "FAILED_RETRYABLE"
    DEAD_LETTER = "DEAD_LETTER"


class LinkTypeEnum(StrEnum):
    SPARK_SOURCE = "SPARK_SOURCE"
    SEMANTIC_RELATED = "SEMANTIC_RELATED"
    USER_MANUAL_LINK = "USER_MANUAL_LINK"
    THREAD_CONTINUATION = "THREAD_CONTINUATION"


class ReminderTypeEnum(StrEnum):
    TIME_SCHEDULED = "TIME_SCHEDULED"
    CONTEXTUAL_MATCH = "CONTEXTUAL_MATCH"
    SPACED_REVIEW = "SPACED_REVIEW"
