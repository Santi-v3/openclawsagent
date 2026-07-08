import type { ProviderRegistryConfig } from "../providers/types";
import { selectProviderForTask } from "../providers/registry";

const config: ProviderRegistryConfig = {
  providers: [
    {
      id: "ollama-local",
      name: "Ollama Local",
      type: "openai-compatible",
      enabled: true,
      costTier: "local",
      baseUrl: "http://localhost:11434/v1",
      apiKeyEnv: null,
      models: [
        {
          id: "qwen-sagent:14b",
          role: ["coding", "local-fallback"],
        },
        {
          id: "gemma4:12b",
          role: ["planning", "chat"],
        },
      ],
    },
    {
      id: "gemini",
      name: "Google Gemini API",
      type: "gemini",
      enabled: false,
      costTier: "free-tier",
      baseUrl: "https://generativelanguage.googleapis.com",
      apiKeyEnv: "GEMINI_API_KEY",
      models: [
        {
          id: "gemini-2.5-flash",
          role: ["planning", "long-context", "general"],
        },
      ],
    },
  ],
  routing: {
    defaultProvider: "ollama-local",
    fallbackOrder: ["ollama-local", "gemini"],
    rules: [
      {
        taskType: "coding",
        preferredRoles: ["coding"],
        fallbackProvider: "ollama-local",
      },
      {
        taskType: "planning",
        preferredRoles: ["planning", "reasoning"],
        fallbackProvider: "ollama-local",
      },
      {
        taskType: "summarization",
        preferredRoles: ["summarization", "cheap"],
        fallbackProvider: "ollama-local",
      },
    ],
  },
  safety: {
    neverSendPatterns: [".env", "api_key", "secret", "token"],
    requireApprovalFor: ["shell", "filesystem_write", "git_push"],
  },
};

for (const taskType of ["coding", "planning", "summarization"]) {
  const selection = selectProviderForTask(config, taskType);

  console.log({
    taskType,
    provider: selection?.provider.id ?? null,
    model: selection?.model.id ?? null,
    reason: selection?.reason ?? "No matching provider/model found",
  });
}
