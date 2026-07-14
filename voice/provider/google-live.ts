import { access, constants } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import type {
  AudioChunk,
  VoiceConnectionConfig,
  VoiceEvent,
  VoiceEventHandler,
  VoiceProvider,
} from "./provider-interface";
import {
  GOOGLE_LIVE_DEFAULTS,
  type GoogleLiveProviderConfig,
  type CredentialSource,
} from "./google-live-config";

export class GoogleLiveProvider implements VoiceProvider {
  private handlers = new Map<string, Set<VoiceEventHandler>>();
  private _state: "idle" | "connecting" | "connected" | "disconnected" | "error" = "idle";
  private config: GoogleLiveProviderConfig = {};
  private abortController: AbortController | null = null;
  private credentialSource: CredentialSource = "none";
  private connectTimeout: ReturnType<typeof setTimeout> | null = null;

  async connect(config: VoiceConnectionConfig): Promise<void> {
    this.validateConfig(config);

    this._state = "connecting";
    this.emit({ type: "state", state: "connecting" });

    this.abortController = new AbortController();
    const signal = this.abortController.signal;

    try {
      await this.performHandshake(config, signal);
      this._state = "connected";
      this.emit({ type: "state", state: "connected" });
    } catch (err) {
      this._state = "error";
      const message = err instanceof Error ? err.message : "Unknown connection error";
      this.emit({ type: "error", message });
      throw new Error(`GoogleLiveProvider: ${message}`);
    }
  }

  async disconnect(): Promise<void> {
    if (this.connectTimeout) {
      clearTimeout(this.connectTimeout);
      this.connectTimeout = null;
    }

    if (this.abortController) {
      this.abortController.abort();
      this.abortController = null;
    }

    this._state = "disconnected";
    this.emit({ type: "state", state: "disconnected" });
  }

  async sendAudio(_chunk: AudioChunk): Promise<void> {
    if (this._state !== "connected") {
      throw new Error("GoogleLiveProvider: not connected");
    }
  }

  async *receiveAudio(): AsyncGenerator<AudioChunk> {
    if (this._state !== "connected") {
      return;
    }

    const chunk: AudioChunk = {
      data: new Uint8Array(0),
      format: "opus",
      sampleRate: 16000,
      timestamp: Date.now(),
    };
    yield chunk;
  }

  supportsRealtime(): boolean {
    return true;
  }

  supportsPhoneCalls(): boolean {
    return false;
  }

  on(event: VoiceEvent["type"], handler: VoiceEventHandler): void {
    const handlers = this.handlers.get(event);
    if (!handlers) {
      this.handlers.set(event, new Set([handler]));
    } else {
      handlers.add(handler);
    }
  }

  get state(): "idle" | "connecting" | "connected" | "disconnected" | "error" {
    return this._state;
  }

  getCredentialSource(): CredentialSource {
    return this.credentialSource;
  }

  getConfig(): GoogleLiveProviderConfig {
    return { ...this.config };
  }

  private emit(event: VoiceEvent): void {
    const handlers = this.handlers.get(event.type);
    if (!handlers) return;
    for (const handler of handlers) {
      handler(event);
    }
  }

  private validateConfig(config: VoiceConnectionConfig): void {
    if (!config.providerId) {
      throw new Error("GoogleLiveProvider: providerId is required");
    }
    if (!config.sessionId) {
      throw new Error("GoogleLiveProvider: sessionId is required");
    }
  }

  private async performHandshake(
    config: VoiceConnectionConfig,
    signal: AbortSignal
  ): Promise<void> {
    const providerConfig = (config.config ?? {}) as GoogleLiveProviderConfig;
    this.config = { ...GOOGLE_LIVE_DEFAULTS, ...providerConfig };

    this.credentialSource = await this.detectCredentialSource();

    if (signal.aborted) {
      throw new Error("connection aborted before handshake");
    }
  }

  private async detectCredentialSource(): Promise<CredentialSource> {
    if (typeof process !== "undefined" && process.env) {
      if (process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY) {
        return "env";
      }
    }

    try {
      const catalogPath = join(
        homedir(),
        ".openclaw",
        "agents",
        "main",
        "agent",
        "plugins",
        "google",
        "catalog.json"
      );
      await access(catalogPath, constants.R_OK);
      return "catalog";
    } catch {
      return "none";
    }
  }

  static async checkConfigured(): Promise<{
    configured: boolean;
    source: CredentialSource;
    model: string;
  }> {
    const provider = new GoogleLiveProvider();
    const source = await provider.detectCredentialSource();
    return {
      configured: source !== "none",
      source,
      model: GOOGLE_LIVE_DEFAULTS.model,
    };
  }
}
