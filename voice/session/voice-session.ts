import type {
  AudioChunk,
  VoiceConnectionConfig,
  VoiceEvent,
  VoiceEventHandler,
  VoiceProvider,
  VoiceSessionState,
} from "../provider/provider-interface";

export interface SessionCallbacks {
  onTranscript?: (text: string, isFinal: boolean) => void;
  onStateChange?: (state: VoiceSessionState) => void;
  onError?: (error: string) => void;
}

export class VoiceSession {
  private provider: VoiceProvider;
  private state: VoiceSessionState = "idle";
  private callbacks: SessionCallbacks;

  constructor(provider: VoiceProvider, callbacks: SessionCallbacks = {}) {
    this.provider = provider;
    this.callbacks = callbacks;
    this.registerProviderEvents();
  }

  private registerProviderEvents(): void {
    this.provider.on("transcript", (event) => {
      if (event.type === "transcript") {
        this.callbacks.onTranscript?.(event.text, event.isFinal);
      }
    });

    this.provider.on("state", (event) => {
      if (event.type === "state") {
        this.state = event.state;
        this.callbacks.onStateChange?.(event.state);
      }
    });

    this.provider.on("error", (event) => {
      if (event.type === "error") {
        this.callbacks.onError?.(event.message);
      }
    });
  }

  async start(config: VoiceConnectionConfig): Promise<void> {
    this.state = "connecting";
    this.callbacks.onStateChange?.("connecting");
    await this.provider.connect(config);
    this.state = "connected";
    this.callbacks.onStateChange?.("connected");
  }

  async stop(): Promise<void> {
    await this.provider.disconnect();
    this.state = "disconnected";
    this.callbacks.onStateChange?.("disconnected");
  }

  async sendAudio(chunk: AudioChunk): Promise<void> {
    await this.provider.sendAudio(chunk);
  }

  async *receiveAudio(): AsyncGenerator<AudioChunk> {
    for await (const chunk of this.provider.receiveAudio()) {
      yield chunk;
    }
  }

  getState(): VoiceSessionState {
    return this.state;
  }

  getProvider(): VoiceProvider {
    return this.provider;
  }
}
