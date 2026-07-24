import type {
  AudioChunk,
  VoiceConnectionConfig,
  VoiceEvent,
  VoiceEventHandler,
  VoiceProvider,
} from "./provider-interface";
import {
  TWILIO_DEFAULTS,
  type TwilioProviderConfig,
  type CredentialStatus,
} from "./twilio-config";

const E164_REGEX = /^\+[1-9][0-9]{6,14}$/;

export function maskPhone(phone: string): string {
  if (!E164_REGEX.test(phone)) {
    return phone;
  }
  const visible = phone.slice(0, 3);
  const suffix = phone.slice(-4);
  return `${visible}****${suffix}`;
}

export function validateE164(phone: string): boolean {
  return E164_REGEX.test(phone);
}

export type TwilioConnectionState = "idle" | "connecting" | "connected" | "disconnected" | "error";

export class TwilioProvider implements VoiceProvider {
  private handlers = new Map<string, Set<VoiceEventHandler>>();
  private _state: TwilioConnectionState = "idle";
  private config: TwilioProviderConfig = {};
  private abortController: AbortController | null = null;
  private connectTimeoutId: ReturnType<typeof setTimeout> | null = null;

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
      throw new Error(`TwilioProvider: ${message}`);
    }
  }

  async disconnect(): Promise<void> {
    if (this.connectTimeoutId) {
      clearTimeout(this.connectTimeoutId);
      this.connectTimeoutId = null;
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
      throw new Error("TwilioProvider: not connected");
    }
  }

  async *receiveAudio(): AsyncGenerator<AudioChunk> {
    if (this._state !== "connected") {
      return;
    }

    const chunk: AudioChunk = {
      data: new Uint8Array(0),
      format: "mulaw",
      sampleRate: 8000,
      timestamp: Date.now(),
    };
    yield chunk;
  }

  supportsRealtime(): boolean {
    return false;
  }

  supportsPhoneCalls(): boolean {
    return true;
  }

  on(event: VoiceEvent["type"], handler: VoiceEventHandler): void {
    const handlers = this.handlers.get(event);
    if (!handlers) {
      this.handlers.set(event, new Set([handler]));
    } else {
      handlers.add(handler);
    }
  }

  get state(): TwilioConnectionState {
    return this._state;
  }

  getConfig(): TwilioProviderConfig {
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
      throw new Error("TwilioProvider: providerId is required");
    }
    if (!config.sessionId) {
      throw new Error("TwilioProvider: sessionId is required");
    }
  }

  private async performHandshake(
    config: VoiceConnectionConfig,
    signal: AbortSignal,
  ): Promise<void> {
    const providerConfig = (config.config ?? {}) as TwilioProviderConfig;
    this.config = { ...TWILIO_DEFAULTS, ...providerConfig };

    const ringTimeout = this.config.ringTimeoutMs ?? TWILIO_DEFAULTS.ringTimeoutMs;
    this.connectTimeoutId = setTimeout(() => {
      if (this._state === "connecting") {
        this._state = "error";
        this.emit({ type: "error", message: "connection timeout" });
      }
    }, ringTimeout);

    if (signal.aborted) {
      throw new Error("connection aborted before handshake");
    }
  }

  static async checkConfigured(): Promise<{
    accountSid: CredentialStatus;
    authToken: CredentialStatus;
    fromNumber: CredentialStatus;
  }> {
    const hasSid = typeof process !== "undefined" && process.env
      ? !!process.env.TWILIO_ACCOUNT_SID
      : false;
    const hasToken = typeof process !== "undefined" && process.env
      ? !!process.env.TWILIO_AUTH_TOKEN
      : false;
    const hasFrom = typeof process !== "undefined" && process.env
      ? !!process.env.TWILIO_FROM_NUMBER
      : false;

    return {
      accountSid: hasSid ? "configured" : "not-configured",
      authToken: hasToken ? "configured" : "not-configured",
      fromNumber: hasFrom ? "configured" : "not-configured",
    };
  }
}
