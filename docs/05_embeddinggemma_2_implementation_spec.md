# 05_EMBEDDING_GEMMA2_SPEC.md
> **LOCAL MULTIMODAL EMBEDDING ENGINE SPECIFICATION (`google/embeddinggemma-2`)**
> This document defines the exact implementation of `app/services/embedder.py` using **`google/embeddinggemma-2`** (Gemma 4 740M multimodal architecture). Coding agents must follow every precision, prefix, token-budget, and normalization rule below without deviation.

---

## 1. Model Architecture & Non-Negotiable Constraints

`google/embeddinggemma-2` combines a 270M text backbone with a 170M vision encoder and a 300M audio encoder, outputting unified **768-dimensional (`768d`) vectors** across an **8,192-token window**.

### 1.1 The Three Iron Rules
1. **NEVER USE `float16` (`torch.float16`):**
   - `EmbeddingGemma 2`'s internal activations exceed the dynamic range of `float16` and will silently produce `NaN` or garbage vectors without raising an exception.
   - Always enforce `torch.bfloat16` (on Ampere+ GPUs or Apple Silicon) or `torch.float32` (on CPU / older GPUs).
2. **Asymmetric Task Prefixes for Text Only:**
   - **Search Queries:** Use `prompt_name="SearchQuery"` (`task: search result | query: {query}`).
   - **Text Documents:** Format as `title: {title or 'none'} | text: {content}` (or `prompt_name="Retrieval-document"`).
   - **Standalone / Interleaved Media:** Never wrap raw image/video/audio objects in text task prefixes.
3. **Full `768d` with L2 Normalization:**
   - Always pass `normalize_embeddings=True` and store the full `768d` vector in PostgreSQL `VECTOR(768)`.

---

## 2. Token Budget Math (`8,192` Max Context Window)

Before calling `.encode()`, `embedder.py` must calculate the multimodal token cost so a single forward pass never exceeds `8,192` tokens:

| Modality | Token Cost Formula | Max Capacity per Single Pass | Default Pipeline Cap |
|---|---|---|---|
| **Text / Code / OCR** | `~1 token per 4 chars` | `8,192 tokens` | `4,000 tokens` per chunk (512-token overlap) |
| **Standard Image** (`<|image|>`) | `280 tokens` (default) | `~29 images` | `280` (or `560` for diagrams) |
| **Book Page Scan** (`<|image|>`) | `1,120 tokens` (`max_soft_tokens=1120`) | `~7 dense pages` | `1 page (1,120 tokens)` + `ocr_text` per chunk |
| **Video / Reel** (`<|video|>`) | `140 tokens / frame` | `~58 frames` | `fps=1, max_frames=32` (`4,480 tokens` max) |
| **Audio / Voice** (`<|audio|>`) | `25 tokens / second` | `~327 seconds (~5.4m)` | First `120 seconds` (`3,000 tokens` max) |

*Note on Combined Reel Budget:*
A 32-frame video (`32 * 140 = 4,480` tokens) + 60 seconds of audio (`60 * 25 = 1,500` tokens) + user note & caption (`~500` tokens) = **`6,480` tokens**, fitting comfortably inside a single `8,192`-token interleaved pass!

---

## 3. Reference Implementation (`app/services/embedder.py`)

Coding agents must implement `EmbeddingGemmaService` using this singleton structure:

```python
from __future__ import annotations

import asyncio
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any, AsyncIterator
import numpy as np
import redis.asyncio as aioredis
import torch
from PIL import Image
from sentence_transformers import SentenceTransformer


class EmbeddingGemmaService:
    """Singleton wrapper around google/embeddinggemma-2 enforcing bfloat16/float32, 768d, and cross-process GPU locking."""

    MODEL_ID = "google/embeddinggemma-2"
    VECTOR_DIM = 768
    REDIS_GPU_LOCK_KEY = "lock:gpu_inference"

    def __init__(
        self,
        redis_client: aioredis.Redis | None = None,
        device: str | None = None,
    ) -> None:
        if device is None:
            device = "cuda" if torch.cuda.is_available() else "cpu"
        self.device = device
        self.redis = redis_client

        # CRITICAL INVARIANT: Never allow float16
        if self.device == "cuda" and torch.cuda.is_bf16_supported():
            self.dtype = torch.bfloat16
        else:
            self.dtype = torch.float32

        self._local_lock = asyncio.Lock()
        self.model = SentenceTransformer(
            self.MODEL_ID,
            device=self.device,
            trust_remote_code=True,
            model_kwargs={"torch_dtype": self.dtype},
        )

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

    async def encode_search_query(self, query_text: str) -> list[float]:
        """Encode user search query using asymmetric SearchQuery prefix."""
        async with self._gpu_mutex():
            vec: np.ndarray = await asyncio.to_thread(
                self.model.encode,
                query_text,
                prompt_name="SearchQuery",
                normalize_embeddings=True,
            )
        self._assert_valid_vector(vec)
        return vec.tolist()

    async def encode_text_document(
        self, title: str | None, content: str
    ) -> list[float]:
        """Encode plain text capture or AI Spark document."""
        clean_title = (title or "none").strip()
        formatted = f"title: {clean_title} | text: {content.strip()}"
        async with self._gpu_mutex():
            vec: np.ndarray = await asyncio.to_thread(
                self.model.encode,
                formatted,
                normalize_embeddings=True,
            )
        self._assert_valid_vector(vec)
        return vec.tolist()

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
        combined_text = "\n".join(text_parts)[:8000]  # Safe char cap alongside image

        payload: dict[str, Any] = {
            "text": f"{combined_text}\n<|image|>" if combined_text else "<|image|>",
            "image": img,
        }

        async with self._gpu_mutex():
            # Configure dynamic soft-token budget for visual documents (280, 560, or 1120)
            if hasattr(self.model[0], "processor") and hasattr(
                self.model[0].processor, "image_processor"
            ):
                self.model[0].processor.image_processor.max_soft_tokens = (
                    soft_token_budget
                )

            vec: np.ndarray = await asyncio.to_thread(
                self.model.encode,
                [payload],
                normalize_embeddings=True,
            )
        result = vec[0]
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
        self._assert_valid_vector(result)
        return result.tolist()

    def _assert_valid_vector(self, vec: np.ndarray) -> None:
        """Guard against silent float16 NaN corruption or dimension mismatch."""
        if vec.shape != (self.VECTOR_DIM,):
            raise ValueError(f"Expected ({self.VECTOR_DIM},), got {vec.shape}")
        if np.isnan(vec).any() or np.isinf(vec).any():
            raise RuntimeError(
                "NaN/Inf detected in EmbeddingGemma 2 output! Verify model is running in bfloat16 or float32."
            )
```

---

## 4. Long-Document, Multi-Page Book Burst & PDF Chunking Policy
1. **Long Web Articles & YouTube Transcripts (`> 4,000` tokens / `~16,000` chars):**
   - Split into semantic Markdown paragraphs/sections of max `3,500` tokens with a `400`-token sliding overlap.
   - Encode each chunk with `title: {extracted_title} | text: {chunk_text}` and store in `embeddings` with `chunk_index = 0, 1, 2...` and `chunk_preview_text = chunk_text[:1200]`.
2. **Multi-Page Burst Book Scans (`book_scan`) & Technical PDFs (`pdf_document`):**
   - For multi-page book scans (`media_assets` ordered by `page_order ASC`) or PDFs (`PyMuPDF` pages), encode **one page per chunk** (`chunk_index = page_order`) using `encode_interleaved_image_or_book(..., soft_token_budget=1120)` combining the active reading session title (`{source_title} - {page_range}`), the page's verbatim OCR/PDF text, and the rendered page `<|image|>`.
   - When the user appends a follow-up note (`capture_annotations`), re-encode `chunk_index = 0` with `annotations_concat` appended so marginalia is immediately reflected in vector search.