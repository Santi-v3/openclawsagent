# Sagent Lab Agent Rules

## Goal

This repository is a side-track spike to build a local Sagent prototype using open-source frameworks.

Primary stack:
- Goose as local agent core candidate
- Ollama as local model runtime
- qwen-sagent:14b as main local model
- Tauri + React later as desktop UI
- MCP tools later, only with explicit approval

## Rules

- Do not work on the old Sagent repository.
- Keep this spike small and experimental.
- Never claim a task is complete unless a file was actually created or changed.
- Never read, print, or modify secrets, .env files, tokens, SSH keys, or credentials.
- Never run destructive commands without explicit approval.
- Never push to GitHub unless explicitly instructed.
- Before creating code, write a short plan.
- After changes, summarize changed files, risks, and next test step.

## First milestone

Create a local agent prototype that can:
1. Chat locally through Goose.
2. Use qwen-sagent:14b through Ollama.
3. Work only inside this sagent-lab folder.
4. Produce a useful Sagent v2 architecture plan.
5. Later generate a tiny Tauri/React proof of concept.
