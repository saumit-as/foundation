import type {
  CaptureBatchRequest,
  CaptureRequest,
  CaptureResponse,
  CookiePayload,
  DeviceConfig,
  PartialCaptureItem,
  RescuePayload,
} from "../types/contracts";

const CONFIG_STORAGE_KEY = "memoria_device_config";

export class MemoriaExtensionApi {
  static async getConfig(): Promise<DeviceConfig | null> {
    const data = await chrome.storage.local.get(CONFIG_STORAGE_KEY);
    return data[CONFIG_STORAGE_KEY] || null;
  }

  static async setConfig(config: DeviceConfig): Promise<void> {
    await chrome.storage.local.set({ [CONFIG_STORAGE_KEY]: config });
  }

  static async clearConfig(): Promise<void> {
    await chrome.storage.local.remove(CONFIG_STORAGE_KEY);
  }

  private static async getAuthHeaders(): Promise<HeadersInit> {
    const config = await this.getConfig();
    if (!config) {
      throw new Error("Extension is not configured. Please paste device credentials in Settings.");
    }
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${config.bearer_key}`,
      "X-Client-Device-Id": config.device_id,
    };
    if (config.cf_access_client_id) {
      headers["CF-Access-Client-Id"] = config.cf_access_client_id;
    }
    if (config.cf_access_client_secret) {
      headers["CF-Access-Client-Secret"] = config.cf_access_client_secret;
    }
    return headers;
  }

  private static async getBaseUrl(): Promise<string> {
    const config = await this.getConfig();
    if (!config || !config.api_base_url) {
      throw new Error("Missing api_base_url in extension settings.");
    }
    return config.api_base_url.replace(/\/+$/, "");
  }

  static async sendCapture(capture: CaptureRequest): Promise<CaptureResponse> {
    const baseUrl = await this.getBaseUrl();
    const headers = await this.getAuthHeaders();
    const resp = await fetch(`${baseUrl}/api/v1/capture`, {
      method: "POST",
      headers,
      body: JSON.stringify(capture),
    });
    if (!resp.ok) {
      const errText = await resp.text();
      throw new Error(`Capture API failed (${resp.status}): ${errText}`);
    }
    return (await resp.json()) as CaptureResponse;
  }

  static async sendCaptureBatch(captures: CaptureRequest[]): Promise<CaptureResponse[]> {
    const baseUrl = await this.getBaseUrl();
    const headers = await this.getAuthHeaders();
    const payload: CaptureBatchRequest = { captures };
    const resp = await fetch(`${baseUrl}/api/v1/capture/batch`, {
      method: "POST",
      headers,
      body: JSON.stringify(payload),
    });
    if (!resp.ok) {
      const errText = await resp.text();
      throw new Error(`Capture batch API failed (${resp.status}): ${errText}`);
    }
    return (await resp.json()) as CaptureResponse[];
  }

  static async getPartialCaptures(): Promise<PartialCaptureItem[]> {
    const baseUrl = await this.getBaseUrl();
    const headers = await this.getAuthHeaders();
    const resp = await fetch(`${baseUrl}/api/v1/captures/partial`, {
      method: "GET",
      headers,
    });
    if (!resp.ok) {
      const errText = await resp.text();
      throw new Error(`Get partial captures failed (${resp.status}): ${errText}`);
    }
    return (await resp.json()) as PartialCaptureItem[];
  }

  static async rescueCapture(
    id: string,
    payload: RescuePayload
  ): Promise<{ status: string; capture_id: string }> {
    const baseUrl = await this.getBaseUrl();
    const headers = await this.getAuthHeaders();
    const resp = await fetch(`${baseUrl}/api/v1/captures/${id}/rescue`, {
      method: "POST",
      headers,
      body: JSON.stringify(payload),
    });
    if (!resp.ok) {
      const errText = await resp.text();
      throw new Error(`Rescue API failed (${resp.status}): ${errText}`);
    }
    return (await resp.json()) as { status: string; capture_id: string };
  }

  static async syncCookies(cookieContent: string): Promise<{ status: string; path: string }> {
    const baseUrl = await this.getBaseUrl();
    const headers = await this.getAuthHeaders();
    const payload: CookiePayload = { cookie_content: cookieContent };
    const resp = await fetch(`${baseUrl}/api/v1/scraper/cookies`, {
      method: "POST",
      headers,
      body: JSON.stringify(payload),
    });
    if (!resp.ok) {
      const errText = await resp.text();
      throw new Error(`Cookie sync failed (${resp.status}): ${errText}`);
    }
    return (await resp.json()) as { status: string; path: string };
  }
}
