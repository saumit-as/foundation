import { defineContentScript } from "wxt/sandbox";
import { Readability } from "@mozilla/readability";
import type { PageContextResult } from "../src/types/contracts";

export default defineContentScript({
  matches: ["<all_urls>"],
  runAt: "document_idle",
  main() {
    chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
      if (message?.type === "EXTRACT_PAGE_CONTEXT") {
        try {
          const selection = window.getSelection()?.toString().trim() || "";
          const url = window.location.href;
          let title = document.title || "";
          let domFallback = "";

          try {
            const docClone = document.cloneNode(true) as Document;
            const reader = new Readability(docClone);
            const article = reader.parse();
            if (article) {
              if (article.title) {
                title = article.title;
              }
              // Extract structured readable text
              domFallback = article.textContent
                ? article.textContent.trim().replace(/\n\s*\n+/g, "\n\n")
                : article.content || "";
            }
          } catch (parseErr) {
            console.warn("Readability parse failed, using innerText:", parseErr);
          }

          if (!domFallback && document.body) {
            domFallback = document.body.innerText.trim();
          }

          const result: PageContextResult = {
            title,
            url,
            selection,
            dom_fallback_markdown: domFallback,
          };

          sendResponse(result);
        } catch (err) {
          console.error("EXTRACT_PAGE_CONTEXT error:", err);
          sendResponse({
            title: document.title || "",
            url: window.location.href,
            selection: "",
            dom_fallback_markdown: document.body ? document.body.innerText.trim() : "",
          });
        }
        return true; // Keep message channel open for async response
      }
    });
  },
});
