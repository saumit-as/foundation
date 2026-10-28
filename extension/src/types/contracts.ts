export type CaptureType =
  | "quick_thought"
  | "url_bookmark"
  | "video_reel"
  | "technical_pdf"
  | "book_scan"
  | "audio_memo"
  | "image_upload";

export type ProcessingStatus =
  | "QUEUED"
  | "SCRAPING"
  | "OCR_IN_PROGRESS"
  | "TRANSCRIBING"
  | "EMBEDDED"
  | "SPARK_EVALUATED"
  | "EXTRACTION_FAILED"
  | "EXTRACTION_PARTIAL";

export interface CaptureRequest {
  id: string; // UUIDv7
  capture_type: CaptureType;
  title: string | null;
  raw_text: string;
  source_url: string | null;
  user_tags: string[];
  captured_at: string; // ISO 8601
  dom_fallback_markdown: string | null;
}

export interface CaptureBatchRequest {
  captures: CaptureRequest[];
}

export interface CaptureResponse {
  status: string;
  id: string;
  processing_status: ProcessingStatus;
  sync_version: number;
}

export interface PartialCaptureItem {
  id: string;
  capture_type: CaptureType;
  processing_status: ProcessingStatus;
  title: string | null;
  raw_text: string;
  source_url: string | null;
  extracted_title: string | null;
  extracted_markdown: string | null;
  user_tags: string[];
  auto_tags: string[];
  captured_at: string;
}

export interface RescuePayload {
  dom_fallback_markdown: string;
  title: string | null;
}

export interface CookiePayload {
  cookie_content: string;
}

export interface DeviceConfig {
  v?: number;
  api_base_url: string;
  cf_access_client_id: string;
  cf_access_client_secret: string;
  device_id: string;
  bearer_key: string;
  ntfy_url?: string;
  ntfy_topic?: string;
  ntfy_token?: string;
  enable_cookie_sync?: boolean;
}

export interface PageContextResult {
  title: string;
  url: string;
  selection: string;
  dom_fallback_markdown: string;
}

export interface OutboxItem extends CaptureRequest {
  queued_at: number;
  retry_count: number;
  last_error?: string;
}
