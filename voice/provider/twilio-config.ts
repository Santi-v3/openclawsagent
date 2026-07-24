export type TwilioRegion = "us1" | "ie1" | "de1" | "sg1" | "jp1" | "au1" | "br1";

export type TunnelProvider = "none" | "ngrok" | "tailscale-serve" | "tailscale-funnel";

export type OutboundDefaultMode = "notify" | "conversation";

export type RealtimeProvider = "google" | "openai" | "none";

export type CredentialStatus = "configured" | "not-configured";

export interface RealtimeConfig {
  enabled: boolean;
  provider: RealtimeProvider;
  streamPath?: string;
}

export interface TwilioProviderConfig {
  accountSid?: string;
  authToken?: string;
  fromNumber?: string;
  toNumber?: string;
  region?: TwilioRegion;
  webhookUrl?: string;
  webhookPath?: string;
  tunnelProvider?: TunnelProvider;
  ringTimeoutMs?: number;
  maxDurationSeconds?: number;
  maxConcurrentCalls?: number;
  outboundDefaultMode?: OutboundDefaultMode;
  realtime?: RealtimeConfig;
  skipSignatureVerification?: boolean;
  mediaStreamPath?: string;
  agentId?: string;
}

export const TWILIO_DEFAULTS = {
  region: "us1" as TwilioRegion,
  webhookPath: "/voice/webhook",
  tunnelProvider: "none" as TunnelProvider,
  ringTimeoutMs: 30_000,
  maxDurationSeconds: 300,
  maxConcurrentCalls: 1,
  outboundDefaultMode: "conversation" as OutboundDefaultMode,
  mediaStreamPath: "/voice/stream",
  agentId: "main",
} as const;

export const MAX_E164_LENGTH = 15;
export const MIN_E164_LENGTH = 7;
