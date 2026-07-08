# OpenClaw as Sagent

## Decision

OpenClaw is the main Sagent runtime.

We will not build a custom Sagent agent core from scratch unless OpenClaw fails the spike.

## Role of sagent-lab

sagent-lab is now used as the control and research repo for:

- OpenClaw setup documentation
- provider strategy
- free-tier model usage
- security supervisor concept
- skill evaluation
- memory strategy
- integration notes
- fallback plans

## Target architecture

OpenClaw provides:

- agent runtime
- skills
- tool execution
- local/self-hosted operation
- messaging/remote-control options
- workspace automation

Sagent additions around OpenClaw provide:

- provider selection strategy
- free-tier API rotation plan
- Security LLM concept
- deterministic policy rules
- audit logging concept
- safe workspace rules
- local memory strategy

## Provider strategy

Preferred provider order:

1. Ollama local fallback
2. Gemini free tier
3. Groq free tier
4. Cloudflare Workers AI
5. OpenRouter free models
6. Optional paid fallback later

## Security strategy

OpenClaw actions should be supervised by:

1. Security LLM
2. deterministic Policy Engine
3. audit logs
4. human approval only for high-risk or unclear actions

See:

- docs/OPENCLAW-SECURITY-SUPERVISOR.md

## Build vs use

Use OpenClaw for:

- main agent runtime
- skills
- automation
- tool workflows

Do not rebuild:

- full agent loop
- full skill system
- full messenger control
- full OpenClaw-like automation layer

Only build custom pieces if OpenClaw does not provide them safely.

## First spike goals

1. Install OpenClaw locally in an isolated test workspace.
2. Configure one safe provider.
3. Test local Ollama if supported.
4. Test one free-tier cloud provider.
5. Inspect provider switching and fallback support.
6. Inspect skill format and permissions.
7. Create one safe custom Sagent skill.
8. Decide whether OpenClaw can remain the long-term Sagent runtime.

## Stop conditions

We stop using OpenClaw as Sagent if:

- provider configuration is too limited
- security controls are not inspectable
- skills cannot be reviewed or limited
- it requires too much trust
- local usage is unstable
- it cannot work with our preferred providers
