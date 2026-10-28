import { useEffect, useRef, useState } from "preact/hooks";
import { MemoriaExtensionApi } from "../../src/utils/api";
import { generateUuidV7 } from "../../src/utils/uuidv7";
import type {
  CaptureType,
  DeviceConfig,
  PageContextResult,
  PartialCaptureItem,
} from "../../src/types/contracts";

export function App() {
  const [activeTab, setActiveTab] = useState<"capture" | "rescue" | "settings">("capture");
  const [config, setConfig] = useState<DeviceConfig | null>(null);

  // Capture tab state
  const [rawText, setRawText] = useState("");
  const [title, setTitle] = useState("");
  const [sourceUrl, setSourceUrl] = useState("");
  const [tags, setTags] = useState("");
  const [captureType, setCaptureType] = useState<CaptureType>("url_bookmark");
  const [domMarkdown, setDomMarkdown] = useState<string | null>(null);
  const [saveStatus, setSaveStatus] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  // Rescue tab state
  const [partialItems, setPartialItems] = useState<PartialCaptureItem[]>([]);
  const [outboxCount, setOutboxCount] = useState(0);
  const [isRescuing, setIsRescuing] = useState(false);
  const [rescueStatus, setRescueStatus] = useState<string | null>(null);

  // Settings tab state
  const [configJsonInput, setConfigJsonInput] = useState("");
  const [cookieSyncEnabled, setCookieSyncEnabled] = useState(false);
  const [settingsStatus, setSettingsStatus] = useState<string | null>(null);

  // Load config and tab details on mount
  useEffect(() => {
    loadConfig();
    initCurrentPageContext();
    loadRescueData();
  }, []);

  async function loadConfig() {
    try {
      const cfg = await MemoriaExtensionApi.getConfig();
      setConfig(cfg);
      if (cfg) {
        setCookieSyncEnabled(Boolean(cfg.enable_cookie_sync));
      }
    } catch (e) {
      console.warn("Failed to load config:", e);
    }
  }

  async function initCurrentPageContext() {
    try {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      if (!tab || !tab.id) return;

      const url = tab.url || "";
      setSourceUrl(url);
      setTitle(tab.title || "");

      // Determine capture type based on URL
      if (url.includes("instagram.com/reel") || url.includes("youtube.com/shorts")) {
        setCaptureType("video_reel");
      } else if (url.endsWith(".pdf") || url.includes("/pdf/")) {
        setCaptureType("technical_pdf");
      } else if (!url.startsWith("http")) {
        setCaptureType("quick_thought");
      } else {
        setCaptureType("url_bookmark");
      }

      // Try reading page context
      try {
        const response = (await chrome.tabs.sendMessage(tab.id, {
          type: "EXTRACT_PAGE_CONTEXT",
        })) as PageContextResult;
        if (response) {
          if (response.selection) {
            setRawText(`"${response.selection}"\n\n`);
          }
          if (response.title) {
            setTitle(response.title);
          }
          if (response.dom_fallback_markdown) {
            setDomMarkdown(response.dom_fallback_markdown);
          }
        }
      } catch {
        // Content script might not be injected or on special chrome:// page
      }
    } catch (e) {
      console.warn("Page context fetch failed:", e);
    }

    setTimeout(() => {
      textareaRef.current?.focus();
    }, 50);
  }

  async function loadRescueData() {
    try {
      const res = await chrome.runtime.sendMessage({ type: "GET_OUTBOX_COUNT" });
      if (res && typeof res.count === "number") {
        setOutboxCount(res.count);
      }
    } catch {}

    try {
      const partials = await MemoriaExtensionApi.getPartialCaptures();
      setPartialItems(partials);
    } catch {
      setPartialItems([]);
    }
  }

  async function handleSaveCapture() {
    if (isSaving) return;
    setIsSaving(true);
    setSaveStatus("Saving...");

    try {
      const tagList = tags
        .split(/[,\s]+/)
        .map((t) => t.replace(/^#/, "").trim())
        .filter(Boolean);

      const payload = {
        id: generateUuidV7(),
        capture_type: captureType,
        title: title || (sourceUrl ? "Web Bookmark" : "Quick Thought"),
        raw_text: rawText.trim() || (sourceUrl ? `Saved bookmark: ${sourceUrl}` : "Empty Note"),
        source_url: sourceUrl || null,
        user_tags: tagList,
        dom_fallback_markdown: domMarkdown,
      };

      const response = await chrome.runtime.sendMessage({
        type: "ENQUEUE_CAPTURE",
        payload,
      });

      if (response?.queued) {
        setSaveStatus("⚡ Stored in offline outbox (will sync when online)");
      } else if (response?.success) {
        setSaveStatus("✓ Captured successfully!");
      } else {
        setSaveStatus(`Error: ${response?.error || "Save failed"}`);
      }

      setTimeout(() => {
        if (response?.success) {
          window.close();
        }
      }, 700);
    } catch (err: any) {
      setSaveStatus(`Failed: ${err?.message || String(err)}`);
    } finally {
      setIsSaving(false);
    }
  }

  function handleKeyDown(e: KeyboardEvent) {
    if ((e.ctrlKey || e.metaKey) && e.key === "Enter") {
      e.preventDefault();
      handleSaveCapture();
    }
  }

  async function handleRescueAll() {
    setIsRescuing(true);
    setRescueStatus("Rescuing partial scrapes in background tabs...");
    try {
      const result = await chrome.runtime.sendMessage({ type: "RESCUE_ALL_PARTIAL" });
      setRescueStatus(
        `Done: Rescued ${result?.rescued ?? 0} items (${result?.errors ?? 0} errors).`
      );
      await loadRescueData();
    } catch (e: any) {
      setRescueStatus(`Rescue error: ${e?.message || String(e)}`);
    } finally {
      setIsRescuing(false);
    }
  }

  async function handleFlushOutbox() {
    try {
      const res = await chrome.runtime.sendMessage({ type: "FLUSH_OUTBOX" });
      setRescueStatus(`Flushed ${res?.flushed ?? 0} items. Remaining: ${res?.remaining ?? 0}`);
      await loadRescueData();
    } catch (e: any) {
      setRescueStatus(`Flush failed: ${e?.message || String(e)}`);
    }
  }

  async function handleSaveSettings() {
    try {
      setSettingsStatus("Saving...");
      let parsed: DeviceConfig;
      if (configJsonInput.trim()) {
        parsed = JSON.parse(configJsonInput);
      } else if (config) {
        parsed = { ...config, enable_cookie_sync: cookieSyncEnabled };
      } else {
        setSettingsStatus("Please paste a valid device JSON bundle.");
        return;
      }

      parsed.enable_cookie_sync = cookieSyncEnabled;
      await MemoriaExtensionApi.setConfig(parsed);
      setConfig(parsed);
      setConfigJsonInput("");
      setSettingsStatus("✓ Settings saved successfully!");
      await loadRescueData();
    } catch (err: any) {
      setSettingsStatus(`JSON Parse Error: ${err?.message || String(err)}`);
    }
  }

  async function handleSyncCookiesNow() {
    setSettingsStatus("Syncing cookies...");
    try {
      const res = await chrome.runtime.sendMessage({ type: "SYNC_COOKIES_NOW" });
      if (res?.success) {
        setSettingsStatus("✓ Netscape cookies synced to server!");
      } else {
        setSettingsStatus(`Cookie sync failed: ${res?.error || "Unknown"}`);
      }
    } catch (e: any) {
      setSettingsStatus(`Error: ${e?.message || String(e)}`);
    }
  }

  return (
    <div className="flex flex-col h-full text-slate-100 bg-slate-900 select-none text-xs">
      {/* Top Header */}
      <div className="flex items-center justify-between px-3 py-2 border-b border-slate-800 bg-slate-950">
        <div className="flex items-center space-x-2">
          <span className="font-bold text-sm tracking-wide text-indigo-400">MEMORIA</span>
          <span className="text-[10px] text-slate-500 bg-slate-800 px-1.5 py-0.5 rounded">v3</span>
        </div>
        <div className="flex space-x-1">
          <button
            onClick={() => setActiveTab("capture")}
            className={`px-2 py-1 rounded text-[11px] font-medium transition ${
              activeTab === "capture" ? "bg-indigo-600 text-white" : "text-slate-400 hover:bg-slate-800"
            }`}
          >
            Capture
          </button>
          <button
            onClick={() => setActiveTab("rescue")}
            className={`px-2 py-1 rounded text-[11px] font-medium relative transition ${
              activeTab === "rescue" ? "bg-indigo-600 text-white" : "text-slate-400 hover:bg-slate-800"
            }`}
          >
            Rescue
            {(partialItems.length > 0 || outboxCount > 0) && (
              <span className="ml-1 px-1 py-0.2 text-[9px] font-bold rounded-full bg-red-500 text-white">
                {partialItems.length + outboxCount}
              </span>
            )}
          </button>
          <button
            onClick={() => setActiveTab("settings")}
            className={`px-2 py-1 rounded text-[11px] font-medium transition ${
              activeTab === "settings" ? "bg-indigo-600 text-white" : "text-slate-400 hover:bg-slate-800"
            }`}
          >
            Settings
          </button>
        </div>
      </div>

      {/* Tab 1: Capture */}
      {activeTab === "capture" && (
        <div className="flex flex-col flex-1 p-3 space-y-2.5">
          <div>
            <label className="block text-[10px] uppercase font-semibold text-slate-400 mb-1">
              Title
            </label>
            <input
              type="text"
              value={title}
              onInput={(e) => setTitle((e.target as HTMLInputElement).value)}
              placeholder="Article or Note Title..."
              className="w-full px-2.5 py-1.5 bg-slate-800/80 border border-slate-700 rounded text-slate-200 text-xs focus:border-indigo-500"
            />
          </div>

          <div className="flex-1 flex flex-col">
            <label className="block text-[10px] uppercase font-semibold text-slate-400 mb-1">
              Thought / Highlights (Markdown)
            </label>
            <textarea
              ref={textareaRef}
              rows={6}
              value={rawText}
              onInput={(e) => setRawText((e.target as HTMLTextAreaElement).value)}
              onKeyDown={handleKeyDown}
              placeholder="Write raw thought, quote, or leave empty to clip page..."
              className="w-full flex-1 p-2.5 bg-slate-800/80 border border-slate-700 rounded text-slate-200 font-mono text-[11px] resize-none focus:border-indigo-500"
            />
          </div>

          <div className="grid grid-cols-2 gap-2">
            <div>
              <label className="block text-[10px] uppercase font-semibold text-slate-400 mb-1">
                Type
              </label>
              <select
                value={captureType}
                onChange={(e) => setCaptureType((e.target as HTMLSelectElement).value as CaptureType)}
                className="w-full px-2 py-1.5 bg-slate-800 border border-slate-700 rounded text-slate-200 text-xs"
              >
                <option value="url_bookmark">URL Bookmark</option>
                <option value="quick_thought">Quick Thought</option>
                <option value="video_reel">Video / Reel</option>
                <option value="technical_pdf">Technical PDF</option>
              </select>
            </div>
            <div>
              <label className="block text-[10px] uppercase font-semibold text-slate-400 mb-1">
                Tags
              </label>
              <input
                type="text"
                value={tags}
                onInput={(e) => setTags((e.target as HTMLInputElement).value)}
                placeholder="#homelab, #research"
                className="w-full px-2.5 py-1.5 bg-slate-800/80 border border-slate-700 rounded text-slate-200 text-xs focus:border-indigo-500"
              />
            </div>
          </div>

          {sourceUrl && (
            <div className="text-[10px] text-slate-400 truncate bg-slate-950/60 p-1.5 rounded border border-slate-800">
              <span className="text-slate-500">Source: </span>
              {sourceUrl}
            </div>
          )}

          {saveStatus && (
            <div className="text-[11px] px-2 py-1 rounded bg-slate-800 text-indigo-300 font-medium text-center">
              {saveStatus}
            </div>
          )}

          <div className="pt-1 flex items-center justify-between">
            <span className="text-[10px] text-slate-500">Ctrl+Enter to Save</span>
            <button
              onClick={handleSaveCapture}
              disabled={isSaving}
              className="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 active:bg-indigo-700 disabled:opacity-50 text-white font-medium rounded shadow transition"
            >
              {isSaving ? "Saving..." : "Capture Thought"}
            </button>
          </div>
        </div>
      )}

      {/* Tab 2: Rescue Queue */}
      {activeTab === "rescue" && (
        <div className="flex flex-col flex-1 p-3 space-y-3">
          <div className="bg-slate-950/80 p-2.5 rounded border border-slate-800">
            <div className="flex items-center justify-between">
              <div>
                <div className="font-semibold text-slate-300">Offline Outbox</div>
                <div className="text-[11px] text-slate-500">{outboxCount} items queued for sync</div>
              </div>
              <button
                onClick={handleFlushOutbox}
                className="px-2.5 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 text-[11px] rounded"
              >
                Flush Outbox
              </button>
            </div>
          </div>

          <div className="flex-1 flex flex-col min-h-0">
            <div className="flex items-center justify-between mb-1.5">
              <span className="font-semibold text-slate-300 text-xs">
                Partial Scrapes ({partialItems.length})
              </span>
              <button
                onClick={handleRescueAll}
                disabled={isRescuing || partialItems.length === 0}
                className="px-2.5 py-1 bg-amber-600 hover:bg-amber-500 disabled:opacity-40 text-white rounded font-medium text-[11px]"
              >
                {isRescuing ? "Rescuing..." : "Rescue All in Tabs"}
              </button>
            </div>

            {rescueStatus && (
              <div className="text-[11px] p-2 mb-2 bg-slate-800 text-amber-300 rounded font-mono">
                {rescueStatus}
              </div>
            )}

            <div className="flex-1 overflow-y-auto space-y-2 pr-1">
              {partialItems.length === 0 ? (
                <div className="text-center py-8 text-slate-500">
                  ✓ No items currently blocked in partial extraction.
                </div>
              ) : (
                partialItems.map((item) => (
                  <div
                    key={item.id}
                    className="p-2 rounded bg-slate-800/80 border border-slate-700/60 space-y-1"
                  >
                    <div className="font-medium text-slate-200 truncate">
                      {item.title || item.extracted_title || "Untitled Partial Item"}
                    </div>
                    <div className="text-[10px] text-indigo-400 truncate">
                      {item.source_url || "No URL"}
                    </div>
                    <div className="text-[9px] text-slate-500">
                      ID: {item.id.slice(0, 8)}... | Status: {item.processing_status}
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      )}

      {/* Tab 3: Settings / Pairing */}
      {activeTab === "settings" && (
        <div className="flex flex-col flex-1 p-3 space-y-3 overflow-y-auto">
          <div>
            <label className="block text-[10px] uppercase font-semibold text-slate-400 mb-1">
              Zero-Trust Device JSON Bundle
            </label>
            <textarea
              rows={4}
              value={configJsonInput}
              onInput={(e) => setConfigJsonInput((e.target as HTMLTextAreaElement).value)}
              placeholder="Paste JSON output from 'python -m app.cli register-device' here..."
              className="w-full p-2 bg-slate-800 border border-slate-700 rounded text-slate-200 font-mono text-[10px] resize-none focus:border-indigo-500"
            />
          </div>

          {config && (
            <div className="p-2.5 rounded bg-slate-950/80 border border-slate-800 text-[10px] space-y-1">
              <div className="text-slate-400 font-semibold">Active Device:</div>
              <div className="text-slate-300 truncate">
                <span className="text-slate-500">Base URL: </span>
                {config.api_base_url}
              </div>
              <div className="text-slate-300 truncate">
                <span className="text-slate-500">Device ID: </span>
                {config.device_id}
              </div>
            </div>
          )}

          <div className="p-2.5 rounded bg-slate-800/60 border border-slate-700 space-y-2">
            <div className="flex items-center justify-between">
              <div>
                <div className="font-medium text-slate-200 text-xs">Netscape Cookie Sync</div>
                <div className="text-[10px] text-slate-400">
                  Sync Instagram/YouTube/X session cookies
                </div>
              </div>
              <input
                type="checkbox"
                checked={cookieSyncEnabled}
                onChange={(e) => setCookieSyncEnabled((e.target as HTMLInputElement).checked)}
                className="w-4 h-4 text-indigo-600 rounded bg-slate-900 border-slate-700 focus:ring-indigo-500"
              />
            </div>

            {cookieSyncEnabled && (
              <button
                onClick={handleSyncCookiesNow}
                className="w-full py-1 text-[11px] bg-slate-700 hover:bg-slate-600 text-slate-200 rounded font-medium"
              >
                Sync Cookies to Home Server Now
              </button>
            )}
          </div>

          {settingsStatus && (
            <div className="text-[11px] px-2.5 py-1.5 rounded bg-slate-800 text-indigo-300 font-medium text-center">
              {settingsStatus}
            </div>
          )}

          <div className="pt-1 flex space-x-2">
            <button
              onClick={handleSaveSettings}
              className="flex-1 py-2 bg-indigo-600 hover:bg-indigo-500 text-white font-medium rounded shadow transition"
            >
              Save Configuration
            </button>
            <button
              onClick={async () => {
                await MemoriaExtensionApi.clearConfig();
                setConfig(null);
                setSettingsStatus("Config cleared.");
              }}
              className="px-3 py-2 bg-slate-800 hover:bg-red-950 hover:text-red-300 text-slate-400 font-medium rounded transition"
            >
              Clear
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
