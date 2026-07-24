import type { VoiceProvider } from "../provider/provider-interface";
import type { VoiceSession } from "../session/voice-session";
import type { TranscriptResult } from "../transcript/transcript";
import type { SummaryResult } from "../summary/summary";
import { GoogleLiveProvider } from "../provider/google-live";
import { TwilioProvider } from "../provider/twilio";

export type ProviderKind = "mock" | "google-live" | "twilio";

export interface PipelineConfig {
  transcriptLanguage?: string;
  summaryMaxLength?: number;
  providerKind?: ProviderKind;
}

export interface PipelineResult {
  transcript: TranscriptResult;
  summary: SummaryResult;
  metadata: {
    duration: number;
    providerId: string;
    timestamp: number;
  };
}

export class VoicePipeline {
  private config: PipelineConfig;

  constructor(config: PipelineConfig = {}) {
    this.config = config;
  }

  async run(session: VoiceSession): Promise<PipelineResult> {
    const provider = session.getProvider();
    const startTime = Date.now();
    const providerId = this.resolveProviderId(provider);

    const segments = [];
    for await (const chunk of session.receiveAudio()) {
      segments.push({
        text: `[audio chunk ${chunk.format} @ ${chunk.sampleRate}Hz]`,
        isFinal: false,
        timestamp: chunk.timestamp,
      });
    }

    const transcript: TranscriptResult = {
      segments,
      fullText: segments.map((s) => s.text).join(" "),
      language: this.config.transcriptLanguage ?? "de-DE",
      duration: Date.now() - startTime,
    };

    const summary: SummaryResult = {
      title: "",
      keyPoints: [],
      fullSummary: "",
      actionItems: [],
      metadata: {
        generatedAt: Date.now(),
        sourceDuration: transcript.duration,
        language: transcript.language,
      },
    };

    return {
      transcript,
      summary,
      metadata: {
        duration: Date.now() - startTime,
        providerId,
        timestamp: Date.now(),
      },
    };
  }

  setConfig(config: Partial<PipelineConfig>): void {
    this.config = { ...this.config, ...config };
  }

  private resolveProviderId(provider: VoiceProvider): string {
    if (provider instanceof GoogleLiveProvider) return "google-live";
    if (provider instanceof TwilioProvider) return "twilio";
    if (provider.supportsPhoneCalls()) return "twilio";
    return "mock";
  }
}
