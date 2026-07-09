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

## Confirmed Gemini backup test

Provider:

Google / Gemini

Model:

google/gemini-2.5-flash-lite

Command:

openclaw agent --agent main --session-key gemini-test-1 --message "Reply with exactly: pong"

Result:

pong

Conclusion:

Gemini works as a backup provider in OpenClaw.

## Confirmed Ollama Cloud backup test

Provider:

Ollama Cloud

Working OpenClaw model:

ollama-cloud/minimax-m3

Important naming note:

- Ollama CLI model name: minimax-m3:cloud
- OpenClaw model name: ollama-cloud/minimax-m3

Command:

openclaw agent --agent main --session-key ollama-cloud-minimax-m3-test --message "Reply with exactly: pong"

Result:

pong

Conclusion:

Ollama Cloud works as an additional backup provider in OpenClaw.

## Current provider pool

Confirmed OpenClaw providers:

1. OpenRouter
   - Working model: openrouter/auto
   - Role: primary Sagent/OpenClaw model

2. Google Gemini
   - Working model: google/gemini-2.5-flash-lite
   - Role: backup provider

3. Ollama Cloud
   - Working model: ollama-cloud/minimax-m3
   - Role: backup provider

Confirmed separate OpenCode worker:

OpenCode Zen Free models remain available even after logging out from Ollama Cloud.

Visible models include:
- opencode/deepseek-v4-flash-free
- opencode/north-mini-code-free
- opencode/nemotron-3-ultra-free
- opencode/mimo-v2.5-free
- opencode/hy3-free

Conclusion:

Sagent currently has three working OpenClaw provider pools plus one separate OpenCode coding-worker pool.
