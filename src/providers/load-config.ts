import { readFile } from "node:fs/promises";
import type { ProviderRegistryConfig } from "./types";

export async function loadProviderRegistryConfig(
  filePath: string
): Promise<ProviderRegistryConfig> {
  const rawConfig = await readFile(filePath, "utf-8");
  const parsedConfig = JSON.parse(rawConfig) as ProviderRegistryConfig;

  validateProviderRegistryConfig(parsedConfig, filePath);

  return parsedConfig;
}

function validateProviderRegistryConfig(
  config: ProviderRegistryConfig,
  filePath: string
): void {
  if (!Array.isArray(config.providers)) {
    throw new Error(`Invalid provider config at ${filePath}: providers must be an array.`);
  }

  if (!config.routing) {
    throw new Error(`Invalid provider config at ${filePath}: routing is required.`);
  }

  if (!Array.isArray(config.routing.fallbackOrder)) {
    throw new Error(
      `Invalid provider config at ${filePath}: routing.fallbackOrder must be an array.`
    );
  }

  if (!Array.isArray(config.routing.rules)) {
    throw new Error(
      `Invalid provider config at ${filePath}: routing.rules must be an array.`
    );
  }

  if (!config.safety) {
    throw new Error(`Invalid provider config at ${filePath}: safety is required.`);
  }

  for (const provider of config.providers) {
    if (!provider.id || !provider.name || !provider.type || !provider.baseUrl) {
      throw new Error(
        `Invalid provider config at ${filePath}: provider is missing required fields.`
      );
    }

    if (!Array.isArray(provider.models)) {
      throw new Error(
        `Invalid provider config at ${filePath}: provider ${provider.id} models must be an array.`
      );
    }
  }
}
