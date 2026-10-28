# 04_EMBEDDING_GEMMA2_AND_HYBRID_SEARCH.md
> **TASK 04: `google/embeddinggemma-2` (`bfloat16`/`float32` `768d`), CHUNKING & HYBRID RRF SEARCH**
> - **Prerequisites:** Task 03 `[x] PASSED`
> - **Reference Spec:** [`docs/05_embeddinggemma_2_implementation_spec.md`](../docs/05_embeddinggemma_2_implementation_spec.md) and [`docs/02_DATABASE_AND_VECTOR_SCHEMA.md`](../docs/02_DATABASE_AND_VECTOR_SCHEMA.md)

---

## 1. Objective
Implement `EmbeddingGemmaService` (`server/app/services/embedder.py`) enforcing the three iron rules of `google/embeddinggemma-2` (**never `float16`**, **asymmetric task prefixes**, and **L2-normalized `768d` vectors**) plus the cross-container Redis distributed GPU mutex (`lock:gpu_inference`) and multi-page/long-document chunking. Then implement the Hybrid RRF + Persona Project Boost search service (`server/app/services/search.py`) and endpoint (`POST /api/v1/search`).

---

## 2. Exact Files to Create / Update

1. `server/pyproject.toml` *(add `torch`, `sentence-transformers>=3.2.0`, `transformers>=4.46.0`)*
2. `server/app/services/__init__.py`
3. `server/app/services/embedder.py`
4. `server/app/services/search.py`
5. `server/app/schemas/search.py`
6. `server/app/api/v1/search.py`
7. `server/app/main.py` *(register `/api/v1/search` router)*
8. `server/tests/test_task_04_embedder_search.py`

---

## 3. Step-by-Step Implementation Instructions

### Step 3.1: Implement `EmbeddingGemmaService` (`server/app/services/embedder.py`)
Follow the reference implementation in `docs/05_embeddinggemma_2_implementation_spec.md` Section 3 & Section 4:
- **Precision Enforcement:**
  ```python
  if self.device == "cuda" and torch.cuda.is_bf16_supported():
      self.dtype = torch.bfloat16
  else:
      self.dtype = torch.float32
  assert self.dtype != torch.float16, "CRITICAL: float16 is strictly forbidden for google/embeddinggemma-2"
  ```
- **Distributed GPU Mutex (`_gpu_mutex`):** Acquire `self._local_lock` (`asyncio.Lock`) and `self.redis.lock("lock:gpu_inference", timeout=120, blocking_timeout=60)`.
- **Methods:**
  - `encode_search_query(query_text: str) -> list[float]` (`prompt_name="SearchQuery"`, `normalize_embeddings=True`)
  - `encode_text_document(title: str | None, content: str) -> list[float]` (`f"title: {clean_title} | text: {content.strip()}"`, `normalize_embeddings=True`)
  - `chunk_and_encode_long_text(title: str | None, content: str, max_chars: int = 14000, overlap_chars: int = 1600) -> list[tuple[int, str, list[float]]]` (splits long Markdown/transcripts into overlapping windows, returning `(chunk_index, chunk_preview_text, vector_768d)`)
  - `encode_interleaved_image_or_book(title, user_note, ocr_text, image_path, soft_token_budget=280) -> list[float]`
  - `encode_interleaved_video_reel(caption_and_note, video_path, audio_path=None, fps=1, max_frames=32) -> list[float]`
  - `_assert_valid_vector(vec: np.ndarray) -> None`: Verifies `vec.shape == (768,)`, `not np.isnan(vec).any()`, `not np.isinf(vec).any()`, and `abs(np.linalg.norm(vec) - 1.0) < 1e-3`.

### Step 3.2: Implement Hybrid RRF Search (`server/app/services/search.py` & `server/app/api/v1/search.py`)
- Fetch the current `PersonaSnapshot` (`is_current = True`) to extract `active_project_slugs: list[str]` from `persona_json["active_projects"]`.
- Encode `request.query` using `embedder.encode_search_query(request.query)`.
- Execute the exact SQL query from `docs/02_DATABASE_AND_VECTOR_SCHEMA.md` Section 5 (`best_vector_per_item` + `vector_matches` + `raw_fts_matches` across both `captures` and `ai_sparks` + `1.15x` Persona boost).
- Return `SearchResponse` with `query_time_ms` and ranked `results`.

---

## 4. `[USER INTERVENTION REQUIRED]` Checkpoint (If `HF_TOKEN` Fails)

If downloading `google/embeddinggemma-2` raises a `401/403 GatedRepoError` from HuggingFace Hub during test execution, pause and display:

```text
[USER INTERVENTION REQUIRED — TASK 04]
Downloading `google/embeddinggemma-2` requires accepting the Gemma license on HuggingFace and setting `HF_TOKEN` in `infra/.env`.
1. Visit https://huggingface.co/google/embeddinggemma-2 and accept the license terms.
2. Paste your read token into `infra/.env` under `HF_TOKEN=hf_...`.
Reply "continue" once updated.
```

---

## 5. Deterministic Verification Gate (`PASS / FAIL`)

Write `server/tests/test_task_04_embedder_search.py` verifying:
1. `embedder.dtype in (torch.bfloat16, torch.float32)` and `embedder.dtype != torch.float16`.
2. `_assert_valid_vector` raises `RuntimeError` if injected with `NaN` or wrong dimensions, and succeeds on a `768d` normalized vector.
3. Long-document chunking splits a 25,000-character Markdown string into overlapping chunks (`chunk_index = 0, 1, ...`), each producing a valid `768d` L2-normalized vector.
4. Inserting 2 `captures` (one matching a `persona_snapshots` active project slug) and 1 `ai_spark` along with their `embeddings` rows, then calling `POST /api/v1/search` returns both `captures` and `ai_sparks` via Hybrid RRF with the `1.15x` Persona project boost applied.

Run:
```powershell
cd server
uv run ruff check .
uv run mypy app
uv run pytest tests/test_task_04_embedder_search.py -v
```
- **Success Criteria:** `0` lint/type errors and `4 passed` in pytest (exit code `0`). Mark **Task 04** as `[x] PASSED` in `tasks/00_TASK_RUNNER_AND_INDEX.md`.
