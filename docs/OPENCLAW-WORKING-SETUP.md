# OpenClaw Working Setup

## Status

OpenClaw works as the current Sagent runtime.

## Confirmed working model

openrouter/openai/gpt-oss-20b:free

## Confirmed test

Command:

openclaw agent --agent main --session-key main --message "Reply with exactly: pong"

Result:

pong

## Working provider

OpenRouter

## Notes

- OpenRouter OAuth/auth is configured in OpenClaw.
- OpenClaw stores auth in its agent SQLite auth store.
- The direct OpenRouter API test also worked with openai/gpt-oss-20b:free.
- Some OpenRouter free models returned 429 rate limits.
- Groq API works directly, but OpenClaw agent runs hit rate limits with tested Groq models.
- Local Ollama models are not used as default because they were unstable/weak for OpenClaw agent runs.

## Current recommendation

Use:

openrouter/openai/gpt-oss-20b:free

as the primary model for the next OpenClaw/Sagent tests.

## Next steps

1. Test normal OpenClaw chat UI.
2. Test a harmless sandbox file task.
3. Add fallback models carefully.
4. Document safe skills and workspace rules.
