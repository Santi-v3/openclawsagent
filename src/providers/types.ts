export type ProviderType =
  | "openai-compatible"
  | "gemini"
  | "cloudflare-workers-ai";

export type CostTier =
  | "local"
  | "free-tier"
  | "cheap"
  | "paid";

export type ModelRole =
  | "coding"
  | "planning"
  | "reasoning"
  | "summarization"
  | "cheap"
  | "fast"
  | "chat"
  | "general"
  | "long-context"
  | "fallback"
  | "local-fallback";

export interface ModelConfig {
  id: string;
  role: ModelRole[];
}

export interface ProviderConfig {
  id: string;
  name: string;
  type: ProviderType;
  enabled: boolean;
  costTier: CostTier;
  baseUrl: string;
  apiKeyEnv: string | null;
  accountIdEnv?: string;
  models: ModelConfig[];
}

export interface RoutingRule {
  taskType: string;
  preferredRoles: ModelRole[];
  fallbackProvider: string;
}

export interface RouterConfig {
  defaultProvider: string;
  fallbackOrder: string[];
  rules: RoutingRule[];
}

export interface SafetyConfig {
  neverSendPatterns: string[];
  requireApprovalFor: string[];
}

export interface ProviderRegistryConfig {
  providers: ProviderConfig[];
  routing: RouterConfig;
  safety: SafetyConfig;
}

export interface ProviderSelection {
  provider: ProviderConfig;
  model: ModelConfig;
  reason: string;
}
