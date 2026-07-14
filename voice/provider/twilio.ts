import type {
  AudioChunk,
  VoiceConnectionConfig,
  VoiceEvent,
  VoiceEventHandler,
  VoiceProvider,
} from "./provider-interface";

export interface TwilioConfig {
  accountSid?: string;
  authToken?: string;
  fromNumber?: string;
}

export class TwilioProvider implements VoiceProvider {
  private handlers = new Map<string, Set<VoiceEventHandler>>();
  private connected = false;

  async connect(_config: VoiceConnectionConfig): Promise<void> {
    this.connected = true;
    this.emit({ type: "state", state: "connected" });
  }

  async disconnect(): Promise<void> {
    this.connected = false;
    this.emit({ type: "state", state: "disconnected" });
  }

  async sendAudio(_chunk: AudioChunk): Promise<void> {
    if (!this.connected) {
      throw new Error("TwilioProvider: not connected");
    }
  }

  async *receiveAudio(): AsyncGenerator<AudioChunk> {
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

  private emit(event: VoiceEvent): void {
    const handlers = this.handlers.get(event.type);
    if (!handlers) return;
    for (const handler of handlers) {
      handler(event);
    }
  }

  get isConnected(): boolean {
    return this.connected;
  }
}
