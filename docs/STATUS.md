# Sagent Status Command

## Purpose

The status command `scripts/sagent-status.sh` provides a single-pane overview of the entire Sagent runtime. It reads data from across the runtime filesystem and displays the current state of all core subsystems.

## Usage

Via Sagent Bridge:

```sh
scripts/sagent-task.sh "/status"
scripts/sagent-task.sh "/sagent status"
```

Directly:

```sh
scripts/sagent-status.sh
```

## What it shows

| Field | Source |
|---|---|
| Security Mode | `~/.openclaw/workspace/settings/security-mode.txt` |
| Auto-Code | `~/.openclaw/workspace/settings/auto-code-routing.txt` |
| ntfy Status | `~/.openclaw/workspace/settings/ntfy-topic.txt` |
| OpenClaw Health | `~/.openclaw/workspace/health/last-health.json` |
| Active Model | `~/.openclaw/workspace/health/last-health.json` |
| Pending Approval | `~/.openclaw/workspace/approvals/pending.json` |
| Last Risk Level | `~/.openclaw/workspace/runs/last-risk.json` |
| Last Exit-Code | `~/.openclaw/workspace/runs/last-command.json` |
| Last Worker | `~/.openclaw/workspace/opencode/last-status.json` |

## Output format

The command prints a formatted text block showing all fields, then writes a JSON summary to:

```
~/.openclaw/workspace/status/last-status-summary.json
```

## JSON summary format

```json
{
  "timestamp": "20250710-120000",
  "security_mode": "approve_dangerous",
  "auto_code": "enabled",
  "ntfy": "not configured",
  "health_status": "healthy",
  "active_model": "openrouter/auto",
  "pending_approval": "none",
  "last_risk_level": 2,
  "last_exit_code": 0,
  "last_worker": "opencode/deepseek-v4-flash-free"
}
```

## Exit code

Always 0 (informational command).
