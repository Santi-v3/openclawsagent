export type GoogleLiveModel =
  | "gemini-2.5-flash-native-audio-preview-12-2025"
  | "google/gemini-3.1-flash-live-preview"
  | "gemini-2.0-flash-live-001";

export type GoogleLiveVoice =
  | "Kore"
  | "Puck"
  | "Charon"
  | "Fenrir"
  | "Leda"
  | "Orus"
  | "Aoede"
  | "Callirrhoe"
  | "Zephyr";

export type GoogleLiveLanguage = "de" | "en" | "fr" | "es" | "it" | "pt";

export type VadSensitivity = "low" | "high";

export type ActivityHandling = "interrupt" | "no-interruption";

export type TurnCoverage =
  | "only-activity"
  | "all-input"
  | "audio-activity-and-all-video";

export type ThinkingLevel =
  | "minimal"
  | "low"
  | "medium"
  | "high";

export type ToolPolicy = "safe-read-only" | "owner" | "none";

export type ConsultPolicy = "auto" | "substantive" | "always";

export type CredentialSource = "env" | "catalog" | "none";

export interface SilenceDetectionConfig {
  prefixPaddingMs?: number;
  silenceDurationMs?: number;
  startSensitivity?: VadSensitivity;
  endSensitivity?: VadSensitivity;
}

export interface VoiceConfig {
  gender?: "female" | "male";
  speed?: number;
}

export interface AgentContextConfig {
  enabled?: boolean;
  maxChars?: number;
  includeIdentity?: boolean;
  includeWorkspaceFiles?: boolean;
  files?: string[];
}

export interface FastContextConfig {
  enabled?: boolean;
  timeoutMs?: number;
  maxResults?: number;
  sources?: string[];
  fallbackToConsult?: boolean;
}

export interface GoogleLiveProviderConfig {
  model?: GoogleLiveModel;
  voice?: GoogleLiveVoice | string;
  speakerVoice?: GoogleLiveVoice | string;
  language?: GoogleLiveLanguage | string;
  apiVersion?: string;
  temperature?: number;
  silenceDetection?: SilenceDetectionConfig;
  voiceConfig?: VoiceConfig;
  activityHandling?: ActivityHandling;
  turnCoverage?: TurnCoverage;
  automaticActivityDetectionDisabled?: boolean;
  enableAffectiveDialog?: boolean;
  sessionResumption?: boolean;
  contextWindowCompression?: boolean;
  thinkingLevel?: ThinkingLevel;
  thinkingBudget?: number;
  systemPrompt?: string;
  toolPolicy?: ToolPolicy;
  consultPolicy?: ConsultPolicy;
  agentContext?: AgentContextConfig;
  fastContext?: FastContextConfig;
  instructions?: string;
  sessionTimeoutMs?: number;
}

export const GOOGLE_LIVE_DEFAULTS = {
  model: "gemini-2.5-flash-native-audio-preview-12-2025" as GoogleLiveModel,
  voice: "Kore" as GoogleLiveVoice,
  apiVersion: "v1beta",
  language: "de",
  temperature: 0.7,
  activityHandling: "interrupt" as ActivityHandling,
  turnCoverage: "only-activity" as TurnCoverage,
  silenceDetection: {
    prefixPaddingMs: 200,
    silenceDurationMs: 500,
    startSensitivity: "high" as VadSensitivity,
    endSensitivity: "high" as VadSensitivity,
  },
  thinkingLevel: "medium" as ThinkingLevel,
  thinkingBudget: 8192,
  enableAffectiveDialog: false,
  sessionResumption: false,
  contextWindowCompression: false,
  sessionTimeoutMs: 120_000,
  toolPolicy: "safe-read-only" as ToolPolicy,
  consultPolicy: "auto" as ConsultPolicy,
} as const;
