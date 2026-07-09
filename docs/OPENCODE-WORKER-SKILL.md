# OpenCode Worker Skill

## Goal

Use OpenCode as a separate coding worker for Sagent/OpenClaw.

OpenClaw remains the main Sagent runtime.
OpenCode handles coding-specific tasks using OpenCode Zen Free models.

## Confirmed working model

opencode/deepseek-v4-flash-free

## Confirmed CLI test

Command:

opencode run --model opencode/deepseek-v4-flash-free "Erkläre kurz die Datei test.js und ändere nichts."

Result:

OpenCode read test.js and explained it without modifying the file.

## Target flow

OpenClaw receives a coding task.

If the task is coding-related, OpenClaw can delegate it to OpenCode:

OpenClaw
→ OpenCode worker command
→ OpenCode Zen Free model
→ result summary / diff
→ OpenClaw/User

## Safety rules

- Only run OpenCode inside an explicitly allowed project directory.
- Never run OpenCode from the home directory.
- Never expose secrets, .env files, SSH keys, API keys, or private tokens.
- Prefer read-only analysis first.
- File writes require an explicit coding task.
- Git push, merge, rebase, or force-push are not allowed by the worker.
- The worker should summarize changed files and risks after each task.

## Candidate worker command

opencode run --model opencode/deepseek-v4-flash-free "<task>"

## Candidate models

- opencode/deepseek-v4-flash-free
- opencode/north-mini-code-free
- opencode/nemotron-3-ultra-free
- opencode/mimo-v2.5-free
- opencode/hy3-free

## Next steps

1. Create a safe test project.
2. Test read-only OpenCode worker tasks.
3. Test one controlled file edit.
4. Design an OpenClaw skill that calls OpenCode in an allowed workspace.
5. Add logs for worker calls and changed files.
