from __future__ import annotations

import logging
import re
import subprocess
from datetime import UTC, datetime
from pathlib import Path
from typing import Any
from uuid import UUID

import httpx
from PIL import Image, ImageOps

from app.core.config import settings

logger = logging.getLogger(__name__)


class PartialExtractionError(Exception):
    """Raised when an external media download is blocked or fails, but OpenGraph metadata was recovered."""

    def __init__(
        self,
        og_title: str | None = None,
        og_description: str | None = None,
        message: str = "Partial extraction fallback",
    ) -> None:
        super().__init__(message)
        self.og_title = og_title
        self.og_description = og_description


def parse_youtube_timestamp(url: str) -> int | None:
    """Parses timestamp parameters like ?t=142s, &t=14m20s, ?t=1h2m3s, &t=142 into total seconds."""
    # Match t=... in query parameters or URL fragment
    match = re.search(r"[?&#]t=([0-9hms]+)", url)
    if not match:
        return None

    raw_val = match.group(1).lower()
    # Check if purely numeric
    if raw_val.isdigit():
        return int(raw_val)

    # Parse components like 1h2m3s, 14m20s, 45s
    hours = 0
    minutes = 0
    seconds = 0

    h_match = re.search(r"(\d+)h", raw_val)
    if h_match:
        hours = int(h_match.group(1))

    m_match = re.search(r"(\d+)m", raw_val)
    if m_match:
        minutes = int(m_match.group(1))

    s_match = re.search(r"(\d+)s", raw_val)
    if s_match:
        seconds = int(s_match.group(1))

    total = hours * 3600 + minutes * 60 + seconds
    return total if total > 0 else None


def compute_clip_range(t_sec: int, window: int = 30) -> tuple[int, int]:
    """Computes a 60-second window [max(0, t - window), t + window] around a timestamp."""
    start = max(0, t_sec - window)
    end = t_sec + window
    return start, end


async def fetch_opengraph_fallback(url: str) -> tuple[str | None, str | None]:
    """Attempts to extract og:title and og:description when direct scraping is blocked."""
    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"
        )
    }
    try:
        async with httpx.AsyncClient(follow_redirects=True, timeout=10.0) as client:
            resp = await client.get(url, headers=headers)
            html = resp.text

            title_m = re.search(
                r'<meta\s+property=["\']og:title["\']\s+content=["\'](.*?)["\']',
                html,
                re.IGNORECASE,
            ) or re.search(
                r'<meta\s+content=["\'](.*?)["\']\s+property=["\']og:title["\']',
                html,
                re.IGNORECASE,
            )

            desc_m = re.search(
                r'<meta\s+property=["\']og:description["\']\s+content=["\'](.*?)["\']',
                html,
                re.IGNORECASE,
            ) or re.search(
                r'<meta\s+content=["\'](.*?)["\']\s+property=["\']og:description["\']',
                html,
                re.IGNORECASE,
            )

            og_title = title_m.group(1).strip() if title_m else None
            og_desc = desc_m.group(1).strip() if desc_m else None
            return og_title, og_desc
    except Exception as exc:
        logger.warning("Failed to fetch OpenGraph metadata for %s: %s", url, exc)
        return None, None


def extract_article(url: str, dom_fallback_markdown: str | None = None) -> tuple[str, str]:
    """Extracts article title and clean Markdown using trafilatura, falling back to dom_fallback_markdown."""
    import trafilatura

    downloaded = trafilatura.fetch_url(url)
    if downloaded:
        result = trafilatura.extract(
            downloaded,
            output_format="markdown",
            include_links=True,
            include_images=False,
            with_metadata=True,
        )
        if result and len(result.strip()) > 50:
            metadata = trafilatura.bare_extraction(downloaded)
            title = None
            if isinstance(metadata, dict):
                title = str(metadata.get("title")) if metadata.get("title") else None
            elif metadata is not None and hasattr(metadata, "title"):
                val = metadata.title
                title = str(val) if val else None
            return title or "Web Article", result

    # Fallback to extension DOM markdown if provided
    if dom_fallback_markdown and len(dom_fallback_markdown.strip()) > 0:
        return "Clipped Web Article", dom_fallback_markdown

    raise ValueError(f"Could not extract article content from {url} and no DOM fallback provided.")


def extract_pdf(pdf_path: Path, capture_id: UUID) -> tuple[str, str, list[dict[str, Any]]]:
    """Extracts text per page from PDF using PyMuPDF and renders dense/graphical pages as images."""
    import fitz  # PyMuPDF

    doc = fitz.open(str(pdf_path))
    full_text_pages: list[str] = []
    rendered_assets: list[dict[str, Any]] = []

    now = datetime.now(UTC)
    target_dir = Path(settings.MEDIA_ROOT) / f"{now.year}" / f"{now.month:02d}" / str(capture_id)
    target_dir.mkdir(parents=True, exist_ok=True)

    title = doc.metadata.get("title") if doc.metadata else None
    if not title:
        title = pdf_path.stem

    for page_idx in range(len(doc)):
        page = doc[page_idx]
        text_content = page.get_text("text").strip()
        if text_content:
            full_text_pages.append(f"### Page {page_idx + 1}\n\n{text_content}")

        # Check if page has images or drawings or dense content to render
        images = page.get_images()
        drawings = page.get_drawings()
        if images or drawings or len(text_content) > 50:
            pix = page.get_pixmap(dpi=150)
            img_filename = f"pdf_page_{page_idx + 1}.jpg"
            img_path = target_dir / img_filename
            pix.save(str(img_path))

            rendered_assets.append(
                {
                    "file_path": str(img_path),
                    "file_name": img_filename,
                    "mime_type": "image/jpeg",
                    "page_order": page_idx + 1,
                    "soft_token_budget": 1120,  # Max visual resolution
                }
            )

    markdown_text = "\n\n---\n\n".join(full_text_pages)
    return title, markdown_text, rendered_assets


def extract_image_or_book_ocr(
    image_paths: list[Path], is_book_scan: bool = False
) -> tuple[str, list[dict[str, Any]]]:
    """Performs verbatim OCR on images/book scans in page order with soft token budgets."""
    ocr_lines: list[str] = []
    media_metadata: list[dict[str, Any]] = []

    # Check for pytesseract or fallback
    has_tesseract = False
    try:
        import pytesseract

        has_tesseract = True
    except ImportError:
        pass

    for order, img_path in enumerate(image_paths, start=1):
        try:
            with Image.open(img_path) as pil_img:
                # Auto-orient via EXIF
                transposed = ImageOps.exif_transpose(pil_img)
                transposed.save(img_path)

                page_text = ""
                if has_tesseract:
                    try:
                        page_text = pytesseract.image_to_string(transposed)
                    except Exception as te:
                        logger.warning("Pytesseract failed on %s: %s", img_path, te)

                word_count = len(page_text.split()) if page_text else 0
                if page_text.strip():
                    ocr_lines.append(f"### Page {order}\n\n{page_text.strip()}")

                # Soft token budget: 1120 for book scans or dense pages >150 words, else 280
                token_budget = 1120 if (is_book_scan or word_count > 150) else 280

                media_metadata.append(
                    {
                        "file_path": str(img_path),
                        "page_order": order,
                        "soft_token_budget": token_budget,
                        "word_count": word_count,
                    }
                )
        except Exception as e:
            logger.error("Error processing image %s: %s", img_path, e)

    return "\n\n".join(ocr_lines), media_metadata


def transcribe_audio(audio_path: Path) -> str:
    """Normalizes audio to 16kHz mono WAV via ffmpeg and transcribes using faster-whisper."""
    # Convert to 16kHz mono WAV if needed
    wav_path = audio_path.with_suffix(".16k.wav")
    try:
        cmd = [
            "ffmpeg",
            "-y",
            "-i",
            str(audio_path),
            "-vn",
            "-acodec",
            "pcm_s16le",
            "-ar",
            "16000",
            "-ac",
            "1",
            str(wav_path),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        target_audio = wav_path
    except Exception as e:
        logger.warning("ffmpeg conversion failed (%s), attempting raw audio transcription", e)
        target_audio = audio_path

    try:
        from faster_whisper import WhisperModel

        model = WhisperModel("base", device="cpu", compute_type="int8")
        segments, _ = model.transcribe(str(target_audio), beam_size=5)
        transcript = " ".join([segment.text.strip() for segment in segments])
        return transcript
    finally:
        if wav_path.exists() and wav_path != audio_path:
            wav_path.unlink(missing_ok=True)


async def extract_video_reel(
    url: str,
    capture_id: UUID,
    cookies_path: Path | None = None,
) -> dict[str, Any]:
    """Downloads reel or timestamped YouTube segment, extracts subtitles, and demuxes audio."""
    import yt_dlp

    now = datetime.now(UTC)
    target_dir = Path(settings.MEDIA_ROOT) / f"{now.year}" / f"{now.month:02d}" / str(capture_id)
    target_dir.mkdir(parents=True, exist_ok=True)

    default_cookies = Path(settings.MEDIA_ROOT) / ".cookies" / "cookies.txt"
    active_cookies = cookies_path or (default_cookies if default_cookies.exists() else None)

    ydl_opts: dict[str, Any] = {
        "quiet": True,
        "noplaylist": True,
    }
    if active_cookies and active_cookies.exists():
        ydl_opts["cookiefile"] = str(active_cookies)

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            if not info:
                raise ValueError("No info returned by yt-dlp")

            title = info.get("title", "Video Reel")
            duration = info.get("duration") or 0

            # Timestamp check
            t_sec = parse_youtube_timestamp(url)

            transcript = ""
            video_file = None
            audio_file = None

            if duration > 600 and not t_sec:
                # Long video without timestamp: subtitle/auto-caption extraction only
                subtitles = info.get("subtitles") or info.get("automatic_captions") or {}
                if subtitles:
                    transcript = f"Auto-captions available for: {title}"
                return {
                    "title": title,
                    "duration": duration,
                    "transcript": transcript,
                    "is_long_form": True,
                }

            # Download video or range clip
            download_opts = dict(ydl_opts)
            download_opts["outtmpl"] = str(target_dir / "video.%(ext)s")
            download_opts["format"] = "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]/best"
            download_opts["max_filesize"] = 80 * 1024 * 1024

            if t_sec:
                start_s, end_s = compute_clip_range(t_sec, 30)
                download_opts["download_ranges"] = yt_dlp.utils.download_range_func(
                    None, [(start_s, end_s)]
                )

            with yt_dlp.YoutubeDL(download_opts) as dl_ydl:
                dl_ydl.download([url])

            # Find downloaded video file
            candidates = list(target_dir.glob("video.*"))
            if candidates:
                video_file = candidates[0]
                # Demux audio
                audio_file = target_dir / "audio_16k.wav"
                cmd = [
                    "ffmpeg",
                    "-y",
                    "-i",
                    str(video_file),
                    "-vn",
                    "-acodec",
                    "pcm_s16le",
                    "-ar",
                    "16000",
                    "-ac",
                    "1",
                    str(audio_file),
                ]
                try:
                    subprocess.run(
                        cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                    )
                    transcript = transcribe_audio(audio_file)
                except Exception as e:
                    logger.warning("Failed to demux audio from video: %s", e)

            return {
                "title": title,
                "duration": duration,
                "transcript": transcript,
                "video_file": str(video_file) if video_file else None,
                "audio_file": str(audio_file) if audio_file else None,
            }

    except Exception as exc:
        if isinstance(exc, yt_dlp.utils.DownloadError):
            og_title, og_desc = await fetch_opengraph_fallback(url)
            raise PartialExtractionError(
                og_title=og_title or "Blocked Media Clip",
                og_description=og_desc,
                message=f"Download blocked by platform: {exc}",
            ) from exc
        raise
