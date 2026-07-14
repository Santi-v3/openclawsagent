export type AudioFormat = "pcm16" | "mulaw" | "opus";

export interface AudioChunk {
  data: Uint8Array;
  format: AudioFormat;
  sampleRate: number;
  timestamp: number;
}

export interface VoiceConnectionConfig {
  providerId: string;
  sessionId: string;
  config?: Record<string, unknown>;
}

export type VoiceSessionState =
  | "idle"
  | "connecting"
  | "connected"
  | "disconnected"
  | "error";

export type VoiceEvent =
  | { type: "audio"; chunk: AudioChunk }
  | { type: "transcript"; text: string; isFinal: boolean }
  | { type: "state"; state: VoiceSessionState }
  | { type: "error"; message: string };

export type VoiceEventHandler = (event: VoiceEvent) => void;

export interface VoiceProvider {
  connect(config: VoiceConnectionConfig): Promise<void>;
  disconnect(): Promise<void>;
  sendAudio(chunk: AudioChunk): Promise<void>;
  receiveAudio(): AsyncGenerator<AudioChunk>;
  supportsRealtime(): boolean;
  supportsPhoneCalls(): boolean;
  on(event: VoiceEvent["type"], handler: VoiceEventHandler): void;
}
