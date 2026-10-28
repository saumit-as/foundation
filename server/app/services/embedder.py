import asyncio
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any

import numpy as np
import redis.asyncio as aioredis
import torch
from PIL import Image
from sentence_transformers import SentenceTransformer

from app.core.config import settings


class EmbeddingGemmaService:
    """Singleton wrapper around google/embeddinggemma-2 enforcing bfloat16/float32, 768d, and cross-process GPU locking."""

    MODEL_ID = "google/embeddinggemma-2"
    VECTOR_DIM = 768
    REDIS_GPU_LOCK_KEY = "lock:gpu_inference"

    def __init__(
        self,
        redis_client: aioredis.Redis | None = None,
        device: str | None = None,
        model: Any | None = None,
        lazy_load: bool = True,
    ) -> None:
        if device is None:
            device = (
                settings.EMBEDDING_DEVICE
                if settings.EMBEDDING_DEVICE
                else ("cuda" if torch.cuda.is_available() else "cpu")
            )
        self.device = device
        self.redis = redis_client

        # CRITICAL INVARIANT: Never allow float16
        if self.device == "cuda" and torch.cuda.is_bf16_supported():
            self.dtype = torch.bfloat16
        else:
            self.dtype = torch.float32

        assert self.dtype != torch.float16, (
            "CRITICAL: float16 is strictly forbidden for google/embeddinggemma-2"
        )

        self._local_lock = asyncio.Lock()
        self._model = model

        if not lazy_load and self._model is None:
            self._load_model()

    def _load_model(self) -> None:
        if self._model is None:
            model_kwargs: dict[str, Any] = {"torch_dtype": self.dtype}
            if settings.HF_TOKEN:
                model_kwargs["token"] = settings.HF_TOKEN

            self._model = SentenceTransformer(
                self.MODEL_ID,
                device=self.device,
                trust_remote_code=True,
                model_kwargs=model_kwargs,
            )

    @property
    def model(self) -> Any:
        if self._model is None:
            self._load_model()
        return self._model

    @asynccontextmanager
    async def _gpu_mutex(self) -> AsyncIterator[None]:
        """Acquire both in-process asyncio lock and cross-container Redis GPU lock."""
        async with self._local_lock:
            if self.redis is not None:
                async with self.redis.lock(
                    self.REDIS_GPU_LOCK_KEY, timeout=120, blocking_timeout=60
                ):
                    yield
            else:
                yield

    def _assert_valid_vector(self, vec: np.ndarray) -> None:
        """Guard against silent float16 NaN corruption, wrong dimensions, or unnormalized vectors."""
        if vec.shape != (self.VECTOR_DIM,):
            raise ValueError(f"Expected ({self.VECTOR_DIM},), got {vec.shape}")
        if np.isnan(vec).any() or np.isinf(vec).any():
            raise RuntimeError(
                "NaN/Inf detected in EmbeddingGemma 2 output! Verify model is running in bfloat16 or float32."
            )
        norm = float(np.linalg.norm(vec))
        if abs(norm - 1.0) > 1e-2:
            raise RuntimeError(
                f"Embedding vector is not L2-normalized! norm={norm:.4f}, expected ~1.0"
            )

    async def encode_search_query(self, query_text: str) -> list[float]:
        """Encode user search query using asymmetric SearchQuery prefix."""
        async with self._gpu_mutex():
            vec: np.ndarray = await asyncio.to_thread(
                self.model.encode,
                query_text,
                prompt_name="SearchQuery",
                normalize_embeddings=True,
            )
        if isinstance(vec, list):
            vec = np.array(vec)
        self._assert_valid_vector(vec)
        return vec.tolist()

    async def encode_text_document(self, title: str | None, content: str) -> list[float]:
        """Encode plain text capture or AI Spark document."""
        clean_title = (title or "none").strip()
        formatted = f"title: {clean_title} | text: {content.strip()}"
        async with self._gpu_mutex():
            vec: np.ndarray = await asyncio.to_thread(
                self.model.encode,
                formatted,
                normalize_embeddings=True,
            )
        if isinstance(vec, list):
            vec = np.array(vec)
        self._assert_valid_vector(vec)
        return vec.tolist()

    async def chunk_and_encode_long_text(
        self,
        title: str | None,
        content: str,
        max_chars: int = 14000,
        overlap_chars: int = 1600,
    ) -> list[tuple[int, str, list[float]]]:
        """Split long document/transcript into overlapping windows, encoding each chunk into a 768d vector."""
        text_len = len(content)
        if text_len <= max_chars:
            vec = await self.encode_text_document(title, content)
            return [(0, content[:1200], vec)]

        chunks: list[tuple[int, str, list[float]]] = []
        step = max_chars - overlap_chars
        chunk_idx = 0
        start = 0

        while start < text_len:
            end = min(start + max_chars, text_len)
            chunk_text = content[start:end]
            preview = chunk_text[:1200]
            chunk_vec = await self.encode_text_document(title, chunk_text)
            chunks.append((chunk_idx, preview, chunk_vec))
            chunk_idx += 1
            if end >= text_len:
                break
            start += step

        return chunks

    async def encode_interleaved_image_or_book(
        self,
        title: str | None,
        user_note: str | None,
        ocr_text: str | None,
        image_path: Path,
        soft_token_budget: int = 280,
    ) -> list[float]:
        """Encode an image or scanned book page interleaved with its text/OCR."""
        img = Image.open(image_path).convert("RGB")
        text_parts = [p for p in [title, user_note, ocr_text] if p and p.strip()]
        combined_text = "\n".join(text_parts)[:8000]

        payload: dict[str, Any] = {
            "text": f"{combined_text}\n<|image|>" if combined_text else "<|image|>",
            "image": img,
        }

        async with self._gpu_mutex():
            if hasattr(self.model, "__getitem__") and hasattr(self.model[0], "processor"):
                proc = getattr(self.model[0], "processor", None)
                if proc and hasattr(proc, "image_processor"):
                    proc.image_processor.max_soft_tokens = soft_token_budget

            vec: np.ndarray = await asyncio.to_thread(
                self.model.encode,
                [payload],
                normalize_embeddings=True,
            )
        result = vec[0]
        if isinstance(result, list):
            result = np.array(result)
        self._assert_valid_vector(result)
        return result.tolist()

    async def encode_interleaved_video_reel(
        self,
        caption_and_note: str,
        video_path: Path,
        audio_path: Path | None = None,
        fps: int = 1,
        max_frames: int = 32,
    ) -> list[float]:
        """Encode a short-form video Reel interleaved with caption + audio in one 768d vector."""
        prompt_tokens = [caption_and_note.strip()[:4000], "<|video|>"]
        payload: dict[str, Any] = {
            "video": str(video_path),
            "fps": fps,
            "max_frames": max_frames,
        }
        if audio_path and audio_path.exists():
            prompt_tokens.append("<|audio|>")
            payload["audio"] = str(audio_path)

        payload["text"] = "\n".join(p for p in prompt_tokens if p)

        async with self._gpu_mutex():
            vec: np.ndarray = await asyncio.to_thread(
                self.model.encode,
                [payload],
                normalize_embeddings=True,
            )
        result = vec[0]
        if isinstance(result, list):
            result = np.array(result)
        self._assert_valid_vector(result)
        return result.tolist()
