import { defineBackground } from "wxt/sandbox";
import { MemoriaExtensionApi } from "../src/utils/api";
import { generateUuidV7 } from "../src/utils/uuidv7";
import type {
  CaptureRequest,
  CaptureType,
  OutboxItem,
  PageContextResult,
  PartialCaptureItem,
} from "../src/types/contracts";

const OUTBOX_STORAGE_KEY = "pending_outbox";
const ALARM_FLUSH_OUTBOX = "flush_outbox";
const ALARM_CHECK_PARTIAL = "check_partial";
const ALARM_SYNC_COOKIES = "sync_cookies";

export default defineBackground(() => {
  // 1. Initial Setup on Installation / Startup
  chrome.runtime.onInstalled.addListener(() => {
    chrome.contextMenus.create({
      id: "memoria-clip-selection",
      title: "Clip to Memoria",
      contexts: ["page", "selection", "link"],
    });

    chrome.alarms.create(ALARM_FLUSH_OUTBOX, { periodInMinutes: 2 });
    chrome.alarms.create(ALARM_CHECK_PARTIAL, { periodInMinutes: 5 });
    chrome.alarms.create(ALARM_SYNC_COOKIES, { periodInMinutes: 360 });

    checkPartialCapturesBadge();
  });

  // 2. Alarm Listeners
  chrome.alarms.onAlarm.addListener(async (alarm) => {
    if (alarm.name === ALARM_FLUSH_OUTBOX) {
      await flushOutbox();
    } else if (alarm.name === ALARM_CHECK_PARTIAL) {
      await checkPartialCapturesBadge();
    } else if (alarm.name === ALARM_SYNC_COOKIES) {
      await syncCookiesIfEnabled();
    }
  });

  // 3. Command / Hotkey Listeners
  chrome.commands.onCommand.addListener(async (command) => {
    if (command === "quick-clip-tab") {
      await handleQuickClipTab();
    } else if (command === "open-scratchpad") {
      // In Manifest V3, chrome.action.openPopup() is available in newer Chromium
      if (chrome.action?.openPopup) {
        chrome.action.openPopup();
      }
    }
  });

  // 4. Context Menu Click Listener
  chrome.contextMenus.onClicked.addListener(async (info, tab) => {
    if (info.menuItemId === "memoria-clip-selection" && tab) {
      await handleClipTabOrSelection(tab, info.selectionText, info.linkUrl);
    }
  });

  // 5. Message Dispatcher for Popup and Helpers
  chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
    if (message?.type === "GET_OUTBOX_COUNT") {
      getOutbox().then((items) => sendResponse({ count: items.length }));
      return true;
    }
    if (message?.type === "ENQUEUE_CAPTURE") {
      enqueueCapture(message.payload).then((res) => sendResponse(res));
      return true;
    }
    if (message?.type === "FLUSH_OUTBOX") {
      flushOutbox().then((res) => sendResponse(res));
      return true;
    }
    if (message?.type === "SYNC_COOKIES_NOW") {
      syncCookiesIfEnabled(true).then((res) => sendResponse(res));
      return true;
    }
    if (message?.type === "RESCUE_ALL_PARTIAL") {
      rescueAllPartialCaptures().then((res) => sendResponse(res));
      return true;
    }
    if (message?.type === "REFRESH_PARTIAL_BADGE") {
      checkPartialCapturesBadge().then((count) => sendResponse({ count }));
      return true;
    }
  });
});

/**
 * Storage helpers for Outbox Queue
 */
async function getOutbox(): Promise<OutboxItem[]> {
  const data = await chrome.storage.local.get(OUTBOX_STORAGE_KEY);
  return (data[OUTBOX_STORAGE_KEY] as OutboxItem[]) || [];
}

async function setOutbox(items: OutboxItem[]): Promise<void> {
  await chrome.storage.local.set({ [OUTBOX_STORAGE_KEY]: items });
}

export async function enqueueCapture(
  payload: Omit<CaptureRequest, "id" | "captured_at"> & { id?: string }
): Promise<{ success: boolean; id: string; queued: boolean; error?: string }> {
  const id = payload.id || generateUuidV7();
  const captureReq: CaptureRequest = {
    ...payload,
    id,
    captured_at: new Date().toISOString(),
  };

  const outboxItem: OutboxItem = {
    ...captureReq,
    queued_at: Date.now(),
    retry_count: 0,
  };

  // Try immediate send
  try {
    await MemoriaExtensionApi.sendCapture(captureReq);
    return { success: true, id, queued: false };
  } catch (err: any) {
    console.warn("Immediate capture failed, saving to local outbox:", err);
    outboxItem.last_error = err?.message || String(err);
    const outbox = await getOutbox();
    outbox.unshift(outboxItem);
    await setOutbox(outbox);
    return { success: true, id, queued: true, error: outboxItem.last_error };
  }
}

/**
 * Flushes pending outbox captures in batches up to 50
 */
export async function flushOutbox(): Promise<{ flushed: number; remaining: number }> {
  const outbox = await getOutbox();
  if (outbox.length === 0) {
    return { flushed: 0, remaining: 0 };
  }

  const batch = outbox.slice(0, 50);
  try {
    await MemoriaExtensionApi.sendCaptureBatch(batch);
    const remaining = outbox.slice(batch.length);
    await setOutbox(remaining);
    return { flushed: batch.length, remaining: remaining.length };
  } catch (err) {
    console.error("Failed to flush outbox batch:", err);
    // Increment retry count
    const updated = outbox.map((item, idx) =>
      idx < batch.length ? { ...item, retry_count: item.retry_count + 1 } : item
    );
    await setOutbox(updated);
    return { flushed: 0, remaining: outbox.length };
  }
}

/**
 * Checks for captures in EXTRACTION_PARTIAL and badges the extension icon
 */
export async function checkPartialCapturesBadge(): Promise<number> {
  try {
    const config = await MemoriaExtensionApi.getConfig();
    if (!config || !config.bearer_key) {
      chrome.action.setBadgeText({ text: "" });
      return 0;
    }
    const partials = await MemoriaExtensionApi.getPartialCaptures();
    const count = partials.length;
    if (count > 0) {
      chrome.action.setBadgeText({ text: String(count) });
      chrome.action.setBadgeBackgroundColor({ color: "#E53E3E" }); // Red badge
    } else {
      chrome.action.setBadgeText({ text: "" });
    }
    return count;
  } catch (err) {
    console.debug("checkPartialCapturesBadge failed (server unconfigured/unreachable):", err);
    return 0;
  }
}

/**
 * 1-Click Rescue of all EXTRACTION_PARTIAL items in background tabs
 */
export async function rescueAllPartialCaptures(): Promise<{ rescued: number; errors: number }> {
  let partials: PartialCaptureItem[] = [];
  try {
    partials = await MemoriaExtensionApi.getPartialCaptures();
  } catch (err) {
    console.error("Failed to fetch partial captures for rescue:", err);
    return { rescued: 0, errors: 1 };
  }

  let rescued = 0;
  let errors = 0;

  for (const item of partials) {
    const targetUrl = item.source_url;
    if (!targetUrl) continue;

    let tabId: number | undefined;
    try {
      const tab = await chrome.tabs.create({ url: targetUrl, active: false });
      tabId = tab.id;

      // Wait for tab to complete loading
      await waitForTabComplete(tabId!);

      // Inject & extract context
      const pageCtx = await extractContextFromTab(tabId!);
      if (pageCtx && pageCtx.dom_fallback_markdown) {
        await MemoriaExtensionApi.rescueCapture(item.id, {
          dom_fallback_markdown: pageCtx.dom_fallback_markdown,
          title: pageCtx.title || item.title || null,
        });
        rescued++;
      } else {
        errors++;
      }
    } catch (rescueErr) {
      console.error(`Rescue failed for capture ${item.id}:`, rescueErr);
      errors++;
    } finally {
      if (tabId) {
        try {
          await chrome.tabs.remove(tabId);
        } catch {}
      }
    }
  }

  await checkPartialCapturesBadge();
  return { rescued, errors };
}

function waitForTabComplete(tabId: number, timeoutMs = 15000): Promise<void> {
  return new Promise((resolve) => {
    let resolved = false;
    const timeout = setTimeout(() => {
      if (!resolved) {
        resolved = true;
        chrome.tabs.onUpdated.removeListener(listener);
        resolve();
      }
    }, timeoutMs);

    const listener = (updatedId: number, changeInfo: chrome.tabs.TabChangeInfo) => {
      if (updatedId === tabId && changeInfo.status === "complete") {
        if (!resolved) {
          resolved = true;
          clearTimeout(timeout);
          chrome.tabs.onUpdated.removeListener(listener);
          resolve();
        }
      }
    };
    chrome.tabs.onUpdated.addListener(listener);
  });
}

async function extractContextFromTab(tabId: number): Promise<PageContextResult | null> {
  try {
    const response = await chrome.tabs.sendMessage(tabId, { type: "EXTRACT_PAGE_CONTEXT" });
    return response as PageContextResult;
  } catch (err) {
    // If content script was not ready, inject script directly
    try {
      const results = await chrome.scripting.executeScript({
        target: { tabId },
        func: () => {
          return {
            title: document.title || "",
            url: window.location.href,
            selection: window.getSelection()?.toString() || "",
            dom_fallback_markdown: document.body ? document.body.innerText.trim() : "",
          };
        },
      });
      if (results && results[0]?.result) {
        return results[0].result as PageContextResult;
      }
    } catch (injectErr) {
      console.warn("Script injection failed:", injectErr);
    }
    return null;
  }
}

/**
 * Opt-In yt-dlp Cookie Sync
 */
export async function syncCookiesIfEnabled(force = false): Promise<{ success: boolean; error?: string }> {
  try {
    const config = await MemoriaExtensionApi.getConfig();
    if (!config || (!config.enable_cookie_sync && !force)) {
      return { success: false, error: "Cookie sync is disabled in settings" };
    }

    const targetDomains = [".instagram.com", ".youtube.com", ".x.com", ".twitter.com"];
    const allCookies: chrome.cookies.Cookie[] = [];

    for (const domain of targetDomains) {
      try {
        const cookies = await chrome.cookies.getAll({ domain });
        allCookies.push(...cookies);
      } catch (cErr) {
        console.warn(`Cookie lookup for domain ${domain} failed:`, cErr);
      }
    }

    if (allCookies.length === 0) {
      return { success: false, error: "No target cookies found" };
    }

    // Format in Netscape cookie jar format
    const lines = [
      "# Netscape HTTP Cookie File",
      "# http://curl.haxx.se/rfc/cookie_spec.html",
      "# This file was generated by Memoria Browser Extension! Edit at your own risk.",
      "",
    ];

    for (const c of allCookies) {
      const domain = c.domain;
      const flag = domain.startsWith(".") ? "TRUE" : "FALSE";
      const path = c.path || "/";
      const secure = c.secure ? "TRUE" : "FALSE";
      const expiry = c.expirationDate ? Math.floor(c.expirationDate) : 0;
      lines.push(`${domain}\t${flag}\t${path}\t${secure}\t${expiry}\t${c.name}\t${c.value}`);
    }

    const netscapeText = lines.join("\n") + "\n";
    await MemoriaExtensionApi.syncCookies(netscapeText);
    return { success: true };
  } catch (err: any) {
    console.error("Cookie sync failed:", err);
    return { success: false, error: err?.message || String(err) };
  }
}

/**
 * Handle quick clip tab (Alt+Shift+C)
 */
async function handleQuickClipTab(): Promise<void> {
  const [activeTab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (!activeTab || !activeTab.id || !activeTab.url) return;

  await handleClipTabOrSelection(activeTab);
}

async function handleClipTabOrSelection(
  tab: chrome.tabs.Tab,
  selectionText?: string,
  linkUrl?: string
): Promise<void> {
  const targetUrl = linkUrl || tab.url || "";
  let extracted: PageContextResult | null = null;

  if (tab.id && !linkUrl) {
    extracted = await extractContextFromTab(tab.id);
  }

  const selection = selectionText || extracted?.selection || "";
  const rawText = selection ? `"${selection}"\n\nClipped from ${targetUrl}` : `Clipped from ${targetUrl}`;
  const title = extracted?.title || tab.title || "Clipped Web Page";

  let captureType: CaptureType = "url_bookmark";
  if (targetUrl.includes("instagram.com/reel") || targetUrl.includes("youtube.com/shorts")) {
    captureType = "video_reel";
  } else if (targetUrl.endsWith(".pdf") || targetUrl.includes("/pdf/")) {
    captureType = "technical_pdf";
  }

  await enqueueCapture({
    capture_type: captureType,
    title,
    raw_text: rawText,
    source_url: targetUrl,
    user_tags: ["web-clip"],
    dom_fallback_markdown: extracted?.dom_fallback_markdown || null,
  });
}
