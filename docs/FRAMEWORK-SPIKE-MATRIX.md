# Framework Spike Matrix

## Goal

Evaluate open-source frameworks as building blocks for Sagent while keeping memory, provider routing, usage tracking, and safety local.

Cloud LLMs may be used as replaceable workers through the provider router. Frameworks must not become the source of truth for memory or permissions.

## Core principle

Sagent owns:
- memory
- workspace scope
- approvals
- provider routing
- usage logs
- safety rules

Frameworks provide:
- coding assistance
- tool execution
- agent workflows
- browser/computer control
- UI inspiration
- MCP integrations

## Candidate frameworks

| Framework | Role in Sagent | Test purpose | Success criteria | Risk |
|---|---|---|---|---|
| OpenCode | Coding agent | Edit/review small repo tasks through provider router | Produces small diffs and follows AGENTS.md | May over-edit or depend on model quality |
| Goose | Tool/agent shell | Test tool use, planning, and MCP-style workflows | Executes tools without raw JSON/tool hallucination | Local models weak; cloud may be needed |
| Hermes Agent | Memory/skills/subagents reference | Study skill and memory architecture | Useful ideas can be adapted into Sagent | Too complex as direct dependency |
| Open Interpreter | Computer/shell control | Test local command execution with approval | Can run safe commands only after approval | Dangerous if permissions are too broad |
| MCP-use / MCP | Tool gateway | Connect providers to tools in a standard way | Tools can be enabled per task and permissioned | Too many tools can overwhelm context |
| Open WebUI | UI/admin reference | Compare model management and chat UX | Useful ideas for provider/model UI | Too large as Sagent core |
| Tauri + React | Final app shell | Build Sagent desktop/web UI | Lightweight local app with clean UI | Requires custom implementation |

## Model strategy

Use models through the provider router:

1. Local Ollama for private/simple tasks.
2. Free-tier cloud models for stronger planning/coding.
3. Paid models only later and only with explicit budget limits.

## First spike order

1. OpenCode with provider-router concept.
2. Goose with cloud-capable provider.
3. Hermes Agent as architecture reference.
4. MCP-use for controlled tool gateway.
5. Tauri + React minimal UI.

## Acceptance criteria for a framework

A framework is useful for Sagent only if it can:

- work with replaceable model providers
- respect local workspace boundaries
- avoid leaking secrets
- support approval before risky actions
- produce inspectable logs or diffs
- be removed later without losing Sagent memory

## Rejected for now

- fully autonomous unattended agents
- direct public internet exposure
- storing memory only inside third-party tools
- enabling all MCPs by default
- cloud model calls without local usage logging
