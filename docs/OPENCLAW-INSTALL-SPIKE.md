# OpenClaw Install Spike

## Goal

Install and evaluate OpenClaw locally as the Sagent runtime in a safe, isolated test setup.

## Current decision

OpenClaw is treated as the main Sagent runtime.

sagent-lab is only the planning, documentation, safety, and evaluation repo.

## Safe install principle

OpenClaw must first run with:

- isolated test workspace
- no real private files
- no real accounts
- no unreviewed third-party skills
- no public internet exposure
- only one limited provider key or local Ollama

## Test workspace

Use:

~/Projects/openclaw-sagent-sandbox

The sandbox may contain:

- fake notes
- fake project files
- test todo lists
- demo scripts
- non-private sample data

The sandbox must not contain:

- .env files
- SSH keys
- iCloud documents
- work documents
- school documents
- banking data
- crypto wallets
- password manager exports
- private photos
- real account data

## Install research tasks

Before installing, verify:

1. Official repository URL.
2. Official installation method.
3. Supported OS for macOS Apple Silicon.
4. Required dependencies.
5. Whether Docker is supported or required.
6. Where OpenClaw stores config.
7. Where OpenClaw stores history/memory.
8. How providers are configured.
9. Whether OpenAI-compatible base URLs are supported.
10. Whether Ollama can be used through http://localhost:11434/v1.
11. Whether multiple providers/fallbacks are supported.
12. How Skills are installed.
13. Whether Skills can be disabled or scoped.
14. Whether tool actions can be reviewed or intercepted.
15. Whether logs include tool calls and file access.

## Provider test order

Start with:

1. Ollama local if supported.
2. One free-tier cloud provider.
3. OpenRouter free model if OpenAI-compatible provider config works.
4. Groq if OpenAI-compatible provider config works.
5. Gemini if native Gemini provider exists or via compatible adapter.
6. Cloudflare Workers AI later.

## First functional tests

Test only harmless tasks:

1. Basic chat.
2. Summarize fake notes.
3. Create a todo file inside sandbox.
4. Read a file inside sandbox.
5. Refuse reading a fake secret file.
6. Run a harmless command only if command execution is visible and controlled.
7. Inspect logs after each action.

## Security questions

OpenClaw can only remain Sagent if:

- provider config is inspectable
- skills are inspectable
- file access can be limited or isolated
- logs are good enough
- unsafe tools can be disabled
- it does not require broad system access from the start
- it can work with free-tier providers and/or local Ollama

## Stop conditions

Stop the spike if OpenClaw:

- requires broad home directory access
- hides tool actions
- installs unknown dependencies without review
- stores secrets insecurely
- cannot be configured with our providers
- exposes a local service publicly by default
- cannot be run inside a safe workspace
