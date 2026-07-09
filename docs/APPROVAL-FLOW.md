# Sagent Approval Flow

## Goal

The approval command lets a human inspect, approve, or deny a pending Sagent Bridge task before OpenClaw executes it.

Pending approvals are created by `scripts/sagent-task.sh` when the current security mode requires human review.

## Commands

### Show status

```sh
scripts/sagent-approval.sh status
```

If no approval is pending, this prints:

```text
No pending approval.
```

If an approval is pending, it prints the pending file path, the task from `pending-task.txt`, and available risk metadata.

### Approve pending task

```sh
scripts/sagent-approval.sh approve
```

This command executes the task from `~/.openclaw/workspace/approvals/pending-task.txt` through OpenClaw and clears the pending approval.

Approval deliberately bypasses the normal security-mode gate because a human has approved the pending task. Risk level 6 remains blocked and returns exit code `20`.

### Deny pending task

```sh
scripts/sagent-approval.sh deny
```

This command archives the pending approval, updates `denied.json`, clears the pending approval, and does not run OpenClaw.

### Help

```sh
scripts/sagent-approval.sh help
```

## Exit Codes

- `0`: command succeeded, or there was no pending approval to act on
- `1`: invalid command or local script error
- `10`: pending approval created by `scripts/sagent-task.sh`
- `20`: denied or blocked task, including risk level 6
- OpenClaw exit code: returned by `scripts/sagent-approval.sh approve` after running an approved task

## Files

### Pending approvals

- `~/.openclaw/workspace/approvals/pending.json`
- `~/.openclaw/workspace/approvals/pending-task.txt`
- `~/.openclaw/workspace/approvals/history/pending-<timestamp>.json`
- `~/.openclaw/workspace/approvals/history/pending-<timestamp>.txt`

### Approved approvals

- `~/.openclaw/workspace/approvals/history/approved-<timestamp>.json`
- `~/.openclaw/workspace/approvals/history/approved-<timestamp>.txt`

### Denied approvals

- `~/.openclaw/workspace/approvals/denied.json`
- `~/.openclaw/workspace/approvals/history/denied-<timestamp>.json`
- `~/.openclaw/workspace/approvals/history/denied-<timestamp>.txt`

### Run logs

- `~/.openclaw/workspace/runs/last-output.txt`
- `~/.openclaw/workspace/runs/last-status.json`
- `~/.openclaw/workspace/runs/last-risk.json`
- `~/.openclaw/workspace/runs/history/run-<timestamp>.txt`
- `~/.openclaw/workspace/runs/history/run-<timestamp>.status.json`
- `~/.openclaw/workspace/runs/history/run-<timestamp>.risk.json`
