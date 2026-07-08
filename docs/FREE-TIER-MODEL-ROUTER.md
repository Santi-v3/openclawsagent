# Free-Tier Model Router Spike

## Goal

Design a model router that can switch between local Ollama models and legitimate free-tier cloud APIs while keeping memory local.

## Provider priority

1. Ollama local
2. Gemini API
3. Groq API
4. Cloudflare Workers AI
5. OpenRouter free models
6. Optional paid fallback later

## Local-first memory

Sagent stores locally:
- conversations
- task summaries
- provider usage
- approvals
- project memory
- workspace metadata

Cloud models receive only:
- current task
- relevant memory summary
- relevant file snippets
- safety rules

Cloud models never receive:
- secrets
- full `.env`
- unnecessary private files
- whole memory database

## Router behavior

1. Classify task type.
2. Pick best available provider.
3. Check rate limit and budget status.
4. Send minimal context.
5. Save response locally.
6. Log provider usage.
7. On rate limit, switch provider.
8. On failure, fall back to local Ollama.
