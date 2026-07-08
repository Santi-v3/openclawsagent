import { loadProviderRegistryConfig } from "../providers/load-config";
import { listEnabledProviders, selectProviderForTask } from "../providers/registry";

const config = await loadProviderRegistryConfig("config/providers.example.json");

console.log("Enabled providers:");
for (const provider of listEnabledProviders(config)) {
  console.log(`- ${provider.id} (${provider.name})`);
}

console.log("\nTask selections:");
for (const taskType of ["coding", "planning", "summarization"]) {
  const selection = selectProviderForTask(config, taskType);

  console.log({
    taskType,
    provider: selection?.provider.id ?? null,
    model: selection?.model.id ?? null,
    reason: selection?.reason ?? "No matching provider/model found",
  });
}
