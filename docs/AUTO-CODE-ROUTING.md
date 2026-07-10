# Auto-Code Routing

## Purpose

Auto-Code Routing lets `scripts/sagent-task.sh` automatically detect coding tasks and route them to the OpenCode worker (`scripts/sagent-opencode-worker.sh`) instead of sending them to OpenClaw.

This means you can type a normal task like:

```sh
scripts/sagent-task.sh "Erstelle eine neue Datei scripts/hello.sh"
```

and if auto-code routing is enabled, Sagent will automatically run the OpenCode worker for this task instead of OpenClaw.

General knowledge questions still go to OpenClaw:

```sh
scripts/sagent-task.sh "Was ist ein LLM?"
```

## Detection Logic

A task is classified as a **coding task** when the lowercase text contains any of:

- Keywords: `erstelle`, `schreibe`, `ändere`, `aendere`, `erzeuge`, `implementiere`, `baue`, `fix`, `repariere`, `bug`, `refactor`, `test`, `pytest`, `npm test`, `lint`, `format`, `git commit`, `git add`
- File extensions: `.py`, `.sh`, `.js`, `.ts`, `.rs`, `.go`, `.java`, `.c`, `.cpp`, `.h`, `.rb`, `.php`, `.css`, `.html`, `.md`, `.json`, `.yaml`, `.yml`, `.toml`, `.env`, `.gitignore`

Everything else is routed to OpenClaw.

## Configuration

The routing setting is stored in:

```text
~/.openclaw/workspace/settings/auto-code-routing.txt
```

Allowed values: `enabled` or `disabled`

Default: `disabled`

## Commands

### Show current status

```sh
scripts/sagent-task.sh "/auto-code"
scripts/sagent-task.sh "/auto-code status"
```

### Enable auto-code routing

```sh
scripts/sagent-task.sh "/auto-code enabled"
scripts/sagent-task.sh "/set auto-code enabled"
```

### Disable auto-code routing

```sh
scripts/sagent-task.sh "/auto-code disabled"
scripts/sagent-task.sh "/set auto-code disabled"
```

### Direct script access

```sh
scripts/sagent-set-auto-code.sh         # show status
scripts/sagent-set-auto-code.sh enabled  # enable
scripts/sagent-set-auto-code.sh disabled # disable
```

## Override

Even when auto-code routing is enabled, you can still force a task to OpenCode or OpenClaw:

- `/opencode <task>` — always routes to OpenCode worker
- Normal tasks without coding keywords — always go to OpenClaw

## Safety

The OpenCode worker always prepends its safety prefix:

> Du bist der Sagent OpenCode Worker. Arbeite nur im aktuellen Projektordner. Lies keine Secrets. Keine .env, keine SSH Keys, keine Tokens. Kein git push, kein deploy, keine externen Aktionen.

This keeps auto-routed tasks read-only by default.

## Dependencies

- `scripts/sagent-set-auto-code.sh` — manages the routing setting
- `scripts/sagent-opencode-worker.sh` — executes the coding task
- `~/.openclaw/workspace/settings/auto-code-routing.txt` — runtime config (not tracked in git)
