# OpenClaw Security Supervisor

## Goal

Use OpenClaw as the main Sagent agent runtime, but supervise risky actions with a separate Security LLM and deterministic policy checks.

The goal is not to require human approval for every action. The goal is safe automation.

## Core architecture

OpenClaw is the main agent.

Before actions are executed, they should be evaluated by:

1. Security LLM
2. Policy Engine
3. Risk Level Rules
4. Audit Log

Human approval is only required for high-risk actions.

## Architecture

OpenClaw Main Agent
→ proposes action
→ Security LLM reviews intent and risk
→ Policy Engine checks hard rules
→ Executor runs allowed action
→ Audit Log stores result

## Decision types

The Security Supervisor can return:

- ALLOW
- DENY
- NEEDS_HUMAN
- MODIFY_REQUEST

## Risk levels

### Risk Level 0: Chat / reasoning only

Examples:
- answer a question
- summarize context
- plan a task
- classify a request

Decision:
- automatic

### Risk Level 1: Read-only in allowed workspace

Examples:
- read files inside sandbox
- list files inside sandbox
- inspect logs
- summarize project files

Decision:
- automatic if policy allows path

### Risk Level 2: Write inside allowed workspace

Examples:
- create notes
- update task files
- edit test files
- write generated drafts

Decision:
- Security LLM required
- Policy Engine must confirm path is allowed

### Risk Level 3: Local commands / tests / git local

Examples:
- run tests
- run formatters
- run safe local scripts
- git diff
- git status
- git commit

Decision:
- Security LLM required
- Policy Engine required
- Audit log required

### Risk Level 4: External writes / account actions / publishing

Examples:
- send email
- send messenger message
- create calendar event
- git push
- merge PR
- publish package
- install software
- change settings in external accounts

Decision:
- Security LLM required
- Human approval required by default

### Risk Level 5: Never allowed

Examples:
- read SSH private keys
- read password manager data
- read banking data
- access crypto wallets
- exfiltrate secrets
- bypass rate limits
- disable security controls
- modify system security settings

Decision:
- always DENY

## Deterministic policy rules

The Policy Engine must block these paths by default:

- ~/.ssh/*
- ~/.gnupg/*
- ~/.aws/*
- ~/.config/gcloud/*
- ~/Library/Keychains/*
- **/.env
- **/.env.*
- **/*secret*
- **/*token*
- **/*private_key*
- **/*.pem
- **/*.key

The Policy Engine must block dangerous commands by default:

- rm -rf /
- sudo rm
- chmod -R 777
- curl ... | sh
- wget ... | sh
- diskutil erase
- mkfs
- dd if=
- killall without explicit target approval
- commands that disable firewalls or security tools

## Security LLM review input

The Security LLM should receive only the minimum needed information:

- action type
- requested tool
- target path or URL
- agent reason
- user goal summary
- expected output
- risk level
- relevant policy context

It should not receive full secrets, credentials, or unnecessary private files.

## Security LLM output schema

{
  "decision": "ALLOW | DENY | NEEDS_HUMAN | MODIFY_REQUEST",
  "riskLevel": 0,
  "reason": "short explanation",
  "conditions": [],
  "blockedBecause": null
}

## Human approval policy

Human approval is not required for every action.

Human approval is required for:

- external write actions
- git push, merge, rebase, force-push
- sending emails or messages
- account changes
- installing software
- enabling new skills
- accessing files outside allowed workspaces
- any action classified as Risk Level 4
- any unclear action where the Security LLM is uncertain

## OpenClaw usage rules

OpenClaw should start in an isolated sandbox.

Allowed at first:

- local test workspace
- local Ollama
- one limited free-tier provider
- no real accounts
- no third-party skills without review

Later:

- add more free-tier providers
- add selected skills
- add controlled external integrations
- add Tailscale-only remote access

## Audit log

Every supervised action should log:

- timestamp
- action type
- tool name
- target path or URL
- selected model/provider
- security decision
- policy decision
- final result
- error if any

## Key principle

Security LLM handles semantic judgment.

Policy Engine handles hard rules.

Human approval is only for high-risk or unclear actions.
