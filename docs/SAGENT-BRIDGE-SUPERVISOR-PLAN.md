# Sagent Bridge + Supervisor Loop Plan

## Goal

Build a safe interface between ChatGPT/Supervisor prompts, OpenClaw, OpenCode, and local automation.

The goal is to let a supervisor LLM or ChatGPT-generated prompt control OpenClaw indirectly, while keeping safety checks, logs, and human approval for risky actions.

## Core architecture

ChatGPT / Supervisor
→ Sagent Bridge
→ Policy / Security Check
→ OpenClaw
→ OpenCode Worker if coding task
→ Logs / Result
→ Supervisor reviews next step
→ Human approval only when needed

## Roles

### ChatGPT / Supervisor

Responsible for:

- planning the next step
- reviewing OpenClaw output
- detecting errors
- suggesting follow-up tasks
- deciding whether to continue, retry, stop, or ask human

### Sagent Bridge

Responsible for:

- receiving tasks
- storing prompts
- enforcing workspace rules
- running OpenClaw commands
- storing outputs/logs
- creating approval requests
- sending notifications via ntfy later

### OpenClaw

Responsible for:

- main local agent runtime
- reading/writing allowed workspace files
- using configured LLM providers
- handling normal assistant tasks

Current working providers:

- openrouter/auto
- google/gemini-2.5-flash-lite
- ollama-cloud/minimax-m3

### OpenCode Worker

Responsible for:

- coding-specific tasks
- repo analysis
- implementation planning
- controlled code edits later

Current working worker model pool:

- opencode/deepseek-v4-flash-free
- opencode/north-mini-code-free
- opencode/nemotron-3-ultra-free
- opencode/mimo-v2.5-free
- opencode/hy3-free

OpenCode remains separate from OpenClaw model providers for now.

## First interface version

Use a simple file-based bridge first.

Suggested paths:

~/.openclaw/workspace/inbox/next-task.txt
~/.openclaw/workspace/runs/last-output.txt
~/.openclaw/workspace/runs/history/
~/.openclaw/workspace/approvals/pending.json
~/.openclaw/workspace/approvals/decisions.json

## First CLI wrapper

Create a local command later:

sagent-task "<task>"

Expected behavior:

1. Save task to inbox.
2. Run policy check.
3. Send task to OpenClaw.
4. Store output.
5. Detect errors or risk.
6. If safe, return output.
7. If risky, create approval request and send notification.

Example OpenClaw call:

openclaw agent --agent main --session-key bridge-run --message "$(cat ~/.openclaw/workspace/inbox/next-task.txt)"

## Safety defaults

Default mode is read-only.

Writing is allowed only when:

- the prompt explicitly requests creating or changing files
- the target path is inside an allowed workspace
- the action is not high-risk
- the policy check passes

## Allowed default workspace

Allowed:

~/.openclaw/workspace/

Allowed project folders can later be registered explicitly.

Not allowed by default:

- ~/
- ~/Desktop
- ~/Downloads
- ~/Documents
- iCloud Drive
- ~/.ssh
- ~/.gnupg
- ~/.aws
- ~/.config/gcloud
- password manager exports
- banking data
- crypto wallets
- private photos
- real account data

## Never-send / never-read patterns

Block by default:

- .env
- .env.*
- *.pem
- *.key
- *secret*
- *token*
- *private_key*
- ~/.ssh/*
- ~/Library/Keychains/*

## Risk levels

### Risk 0: Reasoning only

Examples:

- summarize
- plan
- classify
- explain

Action:

- automatic

### Risk 1: Read inside allowed workspace

Examples:

- read project files
- inspect logs
- summarize notes

Action:

- automatic

### Risk 2: Write inside allowed workspace

Examples:

- create markdown file
- edit test file
- update notes

Action:

- allowed after policy check

### Risk 3: Local commands / tests

Examples:

- run tests
- run formatter
- git status
- git diff
- git commit

Action:

- policy check required
- log required
- human approval optional depending on command

### Risk 4: External writes / publishing

Examples:

- send email
- send message
- create calendar event
- git push
- merge PR
- install software
- change external account settings

Action:

- human approval required

### Risk 5: Never allowed

Examples:

- read SSH private keys
- read password manager data
- access banking data
- access crypto wallets
- disable security controls
- bypass rate limits
- exfiltrate secrets

Action:

- always deny

## Human interaction

Human approval should only be needed for high-risk or unclear actions.

Preferred notification system:

ntfy

Future notification example:

curl -d "Approval needed: OpenClaw wants to edit file X. Approve or deny in Sagent UI." ntfy.sh/<private-topic>

WhatsApp can be considered later, but ntfy is preferred first because it is simpler and safer.

## OpenCode worker integration

OpenCode should not be forced into OpenClaw as a normal LLM provider for now.

Instead:

OpenClaw / Sagent Bridge
→ detects coding task
→ calls OpenCode CLI in allowed project folder
→ OpenCode uses OpenCode Zen Free models
→ result is logged
→ Supervisor reviews output

Example command:

opencode run --model opencode/deepseek-v4-flash-free "<coding task>"

Safety rules for OpenCode worker:

- never run from home directory
- only run inside allowed project folder
- default read-only
- no secrets
- no git push / merge / rebase / force-push
- summarize changed files and risks after edits

## First milestone

Build a simple script:

scripts/sagent-task.sh

It should:

1. accept a task string
2. save it to inbox
3. run a basic policy check
4. call OpenClaw
5. save output to runs/last-output.txt
6. print the result

## Later milestones

1. Add ntfy notifications.
2. Add approval files.
3. Add OpenCode worker delegation.
4. Add Security LLM check.
5. Add local dashboard or TUI.
6. Add Custom GPT / API bridge only after local safety is stable.

## Key principle

Do not connect ChatGPT directly to unrestricted local execution.

Always route through:

Supervisor
→ Sagent Bridge
→ Policy Check
→ OpenClaw/OpenCode
→ Logs
→ Approval when needed

## Security modes

Sagent should support three security modes.

These modes are not feature locks. They define how much human approval is required before actions are executed.

### 1. always_ask

Command:

/set security always_ask

Behavior:

- every task requires approval before execution
- safest mode
- useful during early testing
- useful when Sagent has access to sensitive workspaces or accounts

Example:

Read file
→ approval required

Edit file
→ approval required

Run command
→ approval required

Send message
→ approval required

### 2. approve_dangerous

Command:

/set security approve_dangerous

Behavior:

- default recommended mode
- low-risk and normal tasks run automatically
- dangerous or external-impact actions require approval
- all actions are logged

Automatic examples:

- reasoning
- reading normal project files
- editing normal project files
- running tests
- creating local notes

Approval examples:

- git push
- sending email
- sending WhatsApp/ntfy/Telegram messages
- deleting files
- installing software
- accessing secrets such as .env, API keys, SSH keys
- changing external accounts

### 3. full_access

Command:

/set security full_access

Behavior:

- Sagent can execute tasks without asking
- actions are still logged
- intended for trusted local workflows
- user accepts higher risk

Even in full_access mode, the bridge should still log:

- task
- timestamp
- model/session
- output
- detected risk level
- changed files if known
- exit code

### Security mode storage

Initial simple storage:

~/.openclaw/workspace/settings/security-mode.txt

Allowed values:

always_ask
approve_dangerous
full_access

Default mode:

approve_dangerous

### Future command format

/set security always_ask
/set security approve_dangerous
/set security full_access

The bridge should later parse these commands and update the security mode file.
