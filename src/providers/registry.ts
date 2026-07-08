import type {
  ModelConfig,
  ModelRole,
  ProviderConfig,
  ProviderRegistryConfig,
  ProviderSelection,
} from "./types";

const DEFAULT_FALLBACK_ROLES: ModelRole[] = [
  "general",
  "chat",
  "planning",
  "local-fallback",
];

export function findProviderById(
  config: ProviderRegistryConfig,
  providerId: string
): ProviderConfig | undefined {
  return config.providers.find((provider) => provider.id === providerId);
}

export function findModelsByRole(
  provider: ProviderConfig,
  roles: ModelRole[]
): ModelConfig[] {
  return provider.models.filter((model) =>
    model.role.some((role) => roles.includes(role))
  );
}

export function selectProviderForTask(
  config: ProviderRegistryConfig,
  taskType: string
): ProviderSelection | null {
  const rule = config.routing.rules.find((item) => item.taskType === taskType);

  const preferredRoles = rule?.preferredRoles ?? ["general"];
  const fallbackOrder = config.routing.fallbackOrder;

  const primarySelection = selectFromProviders(
    config,
    fallbackOrder,
    preferredRoles,
    taskType,
    "preferred roles"
  );

  if (primarySelection) {
    return primarySelection;
  }

  return selectFromProviders(
    config,
    fallbackOrder,
    DEFAULT_FALLBACK_ROLES,
    taskType,
    "default fallback roles"
  );
}

function selectFromProviders(
  config: ProviderRegistryConfig,
  providerIds: string[],
  roles: ModelRole[],
  taskType: string,
  strategy: string
): ProviderSelection | null {
  for (const providerId of providerIds) {
    const provider = findProviderById(config, providerId);

    if (!provider || !provider.enabled) {
      continue;
    }

    const matchingModels = findModelsByRole(provider, roles);

    if (matchingModels.length > 0) {
      return {
        provider,
        model: matchingModels[0],
        reason: `Selected ${provider.id}/${matchingModels[0].id} for task type "${taskType}" using ${strategy}: ${roles.join(
          ", "
        )}`,
      };
    }
  }

  return null;
}

export function listEnabledProviders(
  config: ProviderRegistryConfig
): ProviderConfig[] {
  return config.providers.filter((provider) => provider.enabled);
}
