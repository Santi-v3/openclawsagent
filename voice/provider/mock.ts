import type {
  AudioChunk,
  VoiceConnectionConfig,
  VoiceEvent,
  VoiceEventHandler,
  VoiceProvider,
} from "./provider-interface";

export class MockVoiceProvider implements VoiceProvider {
  private connected = false;
  private handlers = new Map<string, Set<VoiceEventHandler>>();

  async connect(_config: VoiceConnectionConfig): Promise<void> {
    this.connected = true;
    this.emit({ type: "state", state: "connected" });
  }

  async disconnect(): Promise<void> {
    this.connected = false;
    this.emit({ type: "state", state: "disconnected" });
  }

  async sendAudio(chunk: AudioChunk): Promise<void> {
    if (!this.connected) {
      throw new Error("MockVoiceProvider: not connected");
    }
    this.emit({ type: "audio", chunk });
  }

  async *receiveAudio(): AsyncGenerator<AudioChunk> {
    const mockChunk: AudioChunk = {
      data: new Uint8Array(0),
      format: "pcm16",
      sampleRate: 16000,
      timestamp: Date.now(),
    };
    yield mockChunk;
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
