# OpenClaw Healthcheck

## Purpose

The healthcheck script `scripts/sagent-healthcheck.sh` tests whether the local OpenClaw agent is running and responsive.

## Checks performed

1. **openclaw command present** — verifies the `openclaw` binary is on `PATH`.
2. **Active model** — reads the currently active model via `openclaw models status --plain`.
3. **Ping test** — sends a message `Antworte exakt mit: pong` through `openclaw agent --agent main` and checks the output contains `pong`.

## Usage

Via Sagent Bridge:

```sh
scripts/sagent-task.sh "/health"
scripts/sagent-task.sh "/openclaw health"
```

Directly:

```sh
scripts/sagent-healthcheck.sh
```

## Exit codes

| Code | Meaning |
|------|---------|
| 0    | healthy — openclaw responded with pong |
| 1    | unhealthy — openclaw did not respond correctly |
| 127  | openclaw command not found on PATH |

## Log files

All logs are written to `~/.openclaw/workspace/health/`:

| File | Description |
|------|-------------|
| `last-health.json` | Latest health status as JSON |
| `last-health-output.txt` | Raw output from the ping test |
| `history/health-<timestamp>.json` | Historical status snapshots |
| `history/health-<timestamp>.txt` | Historical output snapshots |

## JSON status format

```json
{
  "timestamp": "20250710-120000",
  "session_key": "sagent-health-20250710-120000",
  "active_model": "qwen-sagent:14b",
  "status": "healthy",
  "reason": "openclaw returned pong",
  "exit_code": 0,
  "output_file": "/Users/.../.openclaw/workspace/health/last-health-output.txt",
  "history_file": "/Users/.../.openclaw/workspace/health/history/health-20250710-120000.txt"
}
```

## Behaviour notes

- An empty model response is recorded as `"unknown"`.
- The ping test reads `pong` case-insensitively from the output.
- No automatic gateway restart is performed.
