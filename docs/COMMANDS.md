# Sagent Commands

## Purpose

`scripts/sagent-task.sh` accepts two kinds of input:

- Slash commands starting with `/` control the local Sagent Bridge.
- Normal tasks without `/` are sent through the OpenClaw task flow.

Unknown slash commands are not forwarded to OpenClaw. This prevents accidental agent runs when a local bridge command is mistyped.

When auto-code routing is enabled, normal tasks that match coding keywords are automatically routed to the OpenCode worker. See `docs/AUTO-CODE-ROUTING.md` for details.

## Security Commands

Set the security mode:

```sh
scripts/sagent-task.sh "/set security always_ask"
scripts/sagent-task.sh "/set security approve_dangerous"
scripts/sagent-task.sh "/set security full_access"
```

Show the current security mode:

```sh
scripts/sagent-task.sh "/set security"
scripts/sagent-task.sh "/security"
scripts/sagent-task.sh "/security status"
```

## Approval Commands

```sh
scripts/sagent-task.sh "/approval status"
scripts/sagent-task.sh "/approval approve"
scripts/sagent-task.sh "/approval deny"
```

These route to `scripts/sagent-approval.sh` and do not call OpenClaw directly through the normal task path.

## ntfy Commands

Set a local ntfy topic:

```sh
scripts/sagent-task.sh "/set ntfy <topic>"
scripts/sagent-task.sh "/ntfy <topic>"
```

Show ntfy status:

```sh
scripts/sagent-task.sh "/ntfy"
scripts/sagent-task.sh "/ntfy status"
```

Disable ntfy:

```sh
scripts/sagent-task.sh "/set ntfy --disable"
scripts/sagent-task.sh "/ntfy --disable"
```

Do not use secrets, account IDs, or private data in ntfy topics.

## Auto-Code Routing Commands

Show auto-code routing status:

```sh
scripts/sagent-task.sh "/auto-code"
scripts/sagent-task.sh "/auto-code status"
```

Enable or disable auto-code routing:

```sh
scripts/sagent-task.sh "/auto-code enabled"
scripts/sagent-task.sh "/auto-code disabled"
scripts/sagent-task.sh "/set auto-code enabled"
scripts/sagent-task.sh "/set auto-code disabled"
```

When enabled, normal tasks that look like coding tasks (file creation, editing, testing, refactoring) are automatically routed to `scripts/sagent-opencode-worker.sh` instead of OpenClaw. General knowledge questions still go to OpenClaw.

See `docs/AUTO-CODE-ROUTING.md` for the full detection logic and configuration.

## OpenCode Worker Commands

Run an explicit coding task through OpenCode:

```sh
scripts/sagent-task.sh "/opencode <task>"
scripts/sagent-task.sh "/code <task>"
```

These route to `scripts/sagent-opencode-worker.sh` and do not call OpenClaw.

## Status Command

Show the central Sagent runtime status:

```sh
scripts/sagent-task.sh "/status"
scripts/sagent-task.sh "/sagent status"
```

Both route to `scripts/sagent-status.sh`. The status command reads data from all runtime subsystems and displays:

- Security Mode
- Auto-Code routing state
- ntfy notification status
- OpenClaw health status and active model
- Pending approval (if any)
- Last risk level and exit code
- Last OpenCode worker run

Output is written to `~/.openclaw/workspace/status/last-status-summary.json`. See `docs/STATUS.md` for details.

## Healthcheck Commands

Run the OpenClaw healthcheck:

```sh
scripts/sagent-task.sh "/health"
scripts/sagent-task.sh "/openclaw health"
```

Both route to `scripts/sagent-healthcheck.sh`. The healthcheck tests the `openclaw` binary, the active model, and runs a ping test. Logs are written to `~/.openclaw/workspace/health/`. See `docs/HEALTHCHECK.md` for details.

## Help

```sh
scripts/sagent-task.sh "/help"
scripts/sagent-task.sh "/sagent help"
```

## Normal Tasks

Any input that does not start with `/` follows the normal Sagent Bridge flow:

```sh
scripts/sagent-task.sh "Antworte exakt mit: pong"
```

The task is risk-classified, logged, and either sent to OpenClaw or converted into a pending approval depending on the current security mode and risk level.

## Command Logs

Internal slash commands write:

```text
~/.openclaw/workspace/runs/last-command.json
```

The file contains:

- `timestamp`
- `command`
- `routed_to`
- `exit_code`
