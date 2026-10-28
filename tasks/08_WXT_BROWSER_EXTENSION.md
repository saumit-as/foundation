# 08_WXT_BROWSER_EXTENSION.md
> **TASK 08: WXT MANIFEST V3 BROWSER EXTENSION, DOM CLIPPER, OFFLINE OUTBOX, COOKIE SYNC & RESCUE QUEUE**
> - **Prerequisites:** Task 07 `[x] PASSED`
> - **Reference Spec:** [`docs/08_client_and_browser_extension_specs.md`](../docs/08_client_and_browser_extension_specs.md) and [`docs/03_api_and_sync_contract.md`](../docs/03_api_and_sync_contract.md)

---

## 1. Objective
Scaffold `/extension` using **WXT** (Manifest V3), **Preact**, **Tailwind CSS**, and **TypeScript** managed via **`pnpm`**. Implement 1-keystroke capture (`Alt+Shift+C`), the Quick Scratchpad Popup (`Alt+Shift+S`), live DOM extraction via `@mozilla/readability` (`dom_fallback_markdown`), offline outbox queueing (`browser.storage.local` + `browser.alarms`), opt-in `yt-dlp` Netscape cookie jar syncing (`POST /api/v1/scraper/cookies`), and the **1-Click `EXTRACTION_PARTIAL` Rescue Queue** (`GET /api/v1/captures/partial` -> `POST /api/v1/captures/{id}/rescue`).

---

## 2. Exact Files to Create

1. `extension/package.json`
2. `extension/tsconfig.json`
3. `extension/wxt.config.ts`
4. `extension/src/types/contracts.ts`
5. `extension/src/utils/uuidv7.ts`
6. `extension/src/utils/api.ts`
7. `extension/entrypoints/content.ts`
8. `extension/entrypoints/background.ts`
9. `extension/entrypoints/popup/index.html`
10. `extension/entrypoints/popup/main.tsx`
11. `extension/entrypoints/popup/App.tsx`
12. `extension/entrypoints/popup/style.css`

---

## 3. Step-by-Step Implementation Instructions

### Step 3.1: Scaffold `/extension` & Configure `wxt.config.ts`
- Include dependencies in `extension/package.json`: `wxt`, `preact`, `@preact/preset-vite`, `@mozilla/readability`, `tailwindcss`, `typescript`, `@types/chrome`.
- In `wxt.config.ts`, configure Manifest V3 permissions: `["activeTab", "contextMenus", "storage", "scripting", "alarms", "cookies"]`, `host_permissions: ["<all_urls>"]`, and commands:
  - `open-scratchpad` (`Alt+Shift+S`)
  - `quick-clip-tab` (`Alt+Shift+C`)

### Step 3.2: Implement UUIDv7 Generator & Authenticated API Client (`src/utils/uuidv7.ts` & `src/utils/api.ts`)
- Implement a RFC 9562 compliant `generateUuidV7(): string` using `Date.now()` (48-bit timestamp) + `crypto.getRandomValues`.
- Implement `MemoriaExtensionApi` reading connection config (`api_base_url`, `cf_access_client_id`, `cf_access_client_secret`, `device_id`, `bearer_key`, `enable_cookie_sync`) from `browser.storage.local` (importable by pasting the JSON bundle printed by `uv run python -m app.cli register-device --name "WXT-Browser" --type browser_ext`).
- Attach `CF-Access-Client-Id`, `CF-Access-Client-Secret`, `Authorization: Bearer <bearer_key>`, and `X-Client-Device-Id` to every fetch call.

### Step 3.3: Implement Live DOM & Selection Extractor (`entrypoints/content.ts`)
- Listen for message `{ type: "EXTRACT_PAGE_CONTEXT" }`.
- Capture `window.getSelection()?.toString() || ""`.
- Clone `document.cloneNode(true)` and run `new Readability(docClone).parse()` to extract clean article title and HTML/Markdown (`dom_fallback_markdown`).
- Return `{ title, url: window.location.href, selection, dom_fallback_markdown }`.

### Step 3.4: Implement Outbox Queue, Cookie Sync & Rescue Worker (`entrypoints/background.ts`)
1. **Outbox Queue (`pending_outbox[]` in `browser.storage.local`):**
   - On `quick-clip-tab` hotkey, context-menu click, or popup submit: generate `UUIDv7`, prepend to `pending_outbox`, and attempt immediate `POST /api/v1/capture`.
   - If offline or tunnel returns `5xx`, keep in `pending_outbox` and flush via `POST /api/v1/capture/batch` on the 2-minute `flush_outbox` alarm.
2. **Opt-In `yt-dlp` Cookie Sync (`sync_cookies` alarm every 6 hours when enabled):**
   - Export cookies for `.instagram.com`, `.youtube.com`, and `.x.com` via `browser.cookies.getAll`, format in standard Netscape `cookies.txt` format, and send `POST /api/v1/scraper/cookies`.
3. **1-Click `EXTRACTION_PARTIAL` Rescue Worker:**
   - Poll `GET /api/v1/captures/partial` every 5 minutes and update the extension badge count (`browser.action.setBadgeText`).
   - When the user clicks **"Rescue Blocked URLs"** in the popup, open each partial URL in a background tab (`active: false`), execute `EXTRACT_PAGE_CONTEXT`, send `POST /api/v1/captures/{id}/rescue`, and close the tab.

### Step 3.5: Implement Preact Popup UI (`entrypoints/popup/App.tsx`)
Build a fast, keyboard-first Preact UI with 3 tabs:
1. **Capture Tab (Default):** Auto-focused note textarea, `#tags` input, pre-filled current tab URL/selection, and `Ctrl+Enter` to save in `<15ms`.
2. **Rescue Queue Tab:** Lists mobile-shared items in `EXTRACTION_PARTIAL` with a **"Rescue All in Background"** button and outbox sync status (`Pending: N`).
3. **Settings / Pairing Tab:** Textarea to paste the JSON bundle from `app.cli register-device` + toggle for `Sync Instagram/YouTube/X Cookies to Home Server`.

---

## 4. `[USER INTERVENTION REQUIRED]` Checkpoint (Optional Browser Load)

Once the build succeeds, display:
```text
[USER INTERVENTION REQUIRED — TASK 08 (OPTIONAL MANUAL CHECK)]
The WXT Manifest V3 extension has been compiled to `extension/.output/chrome-mv3`.
To load it in Chrome/Brave/Edge:
1. Open `chrome://extensions`, enable "Developer mode", and click "Load unpacked" -> select `extension/.output/chrome-mv3`.
2. Run `cd server && uv run python -m app.cli register-device --name "WXT-Browser" --type browser_ext` and paste the JSON output into the extension's Settings tab.
```

---

## 5. Deterministic Verification Gate (`PASS / FAIL`)

Run the following commands inside `/extension`. **All 3 checks must exit with code `0`:**

```powershell
cd extension
pnpm install
pnpm tsc --noEmit
pnpm wxt build
```
- **Verify Build Output Exists:**
  ```powershell
  Test-Path "extension/.output/chrome-mv3/manifest.json"
  ```
  - **Expected Output:** `True`

Once `pnpm tsc --noEmit` exits `0` and `manifest.json` is generated, mark **Task 08** as `[x] PASSED` in `tasks/00_TASK_RUNNER_AND_INDEX.md`.
