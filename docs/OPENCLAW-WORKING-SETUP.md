# OpenClaw Working Setup

## Status

OpenClaw works as the current Sagent runtime.

## Working default model

openrouter/auto

## Confirmed test

Command:

openclaw agent --agent main --session-key auto-test-1 --message "Reply with exactly: pong"

Result:

pong

## Notes

- OpenRouter authentication works.
- Fixed OpenRouter free models can be unstable or rate-limited.
- openrouter/auto works better because OpenRouter can route to an available model.
- Groq works directly via API, but OpenClaw agent context can exceed Groq TPM limits.
- Local Ollama models are not used as default because they were weak/unstable for OpenClaw agent runs.

## Current recommendation

Use openrouter/auto as the primary OpenClaw/Sagent model.

## Next steps

1. Test harmless sandbox file tasks.
2. Keep skills disabled unless reviewed.
3. Add security supervisor notes.
4. Later test fallback models only if needed.
