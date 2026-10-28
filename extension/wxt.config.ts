import { defineConfig } from "wxt";
import preact from "@preact/preset-vite";

// See https://wxt.dev/api/config.html
export default defineConfig({
  vite: () => ({
    plugins: [preact()],
  }),
  manifest: {
    name: "Memoria Scratchpad & Ingestion Clipper",
    description: "Fast capture scratchpad, DOM clipper, cookie sync, and partial scrape rescue",
    version: "1.0.0",
    permissions: [
      "activeTab",
      "contextMenus",
      "storage",
      "scripting",
      "alarms",
      "cookies",
    ],
    host_permissions: ["<all_urls>"],
    commands: {
      "open-scratchpad": {
        suggested_key: {
          default: "Alt+Shift+S",
        },
        description: "Open Quick Scratchpad Popup",
      },
      "quick-clip-tab": {
        suggested_key: {
          default: "Alt+Shift+C",
        },
        description: "Silent 1-Keystroke Clip Current Tab",
      },
    },
    action: {
      default_title: "Memoria Scratchpad",
    },
  },
});
