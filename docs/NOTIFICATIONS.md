# Sagent Notifications

## Goal

Sagent can optionally send an ntfy push notification when a task needs human approval.

Notifications are best-effort only. If ntfy is not configured, `curl` is unavailable, or the request fails, the Sagent approval flow continues.

## Setup

Choose a private, hard-to-guess topic and configure it locally:

```sh
scripts/sagent-set-ntfy.sh <topic>
```

The topic is stored in:

```text
~/.openclaw/workspace/settings/ntfy-topic.txt
```

The default server is:

```text
https://ntfy.sh
```

## Status

```sh
scripts/sagent-set-ntfy.sh
```

If no topic is configured, it prints:

```text
ntfy topic: not configured
```

## Disable

```sh
scripts/sagent-set-ntfy.sh --disable
```

This removes the local topic setting.

## Test

```sh
scripts/sagent-notify.sh "Sagent test" "Hello"
```

If ntfy is not configured, the command exits successfully after printing:

```text
ntfy not configured; skipping notification.
```

## Approval Notifications

`scripts/sagent-task.sh` sends an ntfy notification when it creates a pending approval:

- `always_ask`: every pending approval
- `approve_dangerous`: risk level 4 or 5 pending approvals

The notification includes:

- security mode
- risk level
- risk reason
- a short task excerpt
- the approval commands to run next

## Security Notes

- Do not use secrets, names, account IDs, or private data in ntfy topics.
- Use a long, random, hard-to-guess topic.
- Do not commit local ntfy topic files.
- Risk level 5 tasks are sensitive. Their notification hides the task text and sends only:

```text
Task hidden because risk level is sensitive.
```
