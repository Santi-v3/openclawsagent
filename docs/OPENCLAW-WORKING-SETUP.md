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

## Confirmed sandbox read test

Created test file:

~/.openclaw/workspace/sagent-test/notes.txt

Content:

Sagent test note:
- Use OpenClaw as runtime.
- Use OpenRouter auto as model.
- Keep skills disabled unless reviewed.

Prompt in OpenClaw chat:

Lies die Datei sagent-test/notes.txt und fasse sie in 3 Stichpunkten zusammen. Ändere keine Dateien.

Result:

- OpenClaw als Laufzeitumgebung verwenden.
- OpenRouter auto als Modell nutzen.
- Skills deaktiviert lassen, es sei denn, sie wurden überprüft.

Conclusion:

OpenClaw can read and summarize files inside the sandbox workspace while using openrouter/auto.

## Confirmed sandbox write test

Prompt in OpenClaw chat:

Erstelle im Ordner sagent-test eine Datei write-test.md mit einer kurzen Checkliste für sichere OpenClaw-Nutzung. Nutze nur diesen Ordner und ändere keine anderen Dateien.

Created file:

~/.openclaw/workspace/sagent-test/write-test.md

Result:

OpenClaw created a Markdown checklist for safe OpenClaw usage inside the sandbox workspace.

Conclusion:

OpenClaw can write files inside the sandbox workspace while using openrouter/auto.
