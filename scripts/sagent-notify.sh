#!/usr/bin/env bash
set -euo pipefail

TITLE="${1:-}"
MESSAGE="${2:-}"

WORKSPACE="$HOME/.openclaw/workspace"
SETTINGS_DIR="$WORKSPACE/settings"
NTFY_TOPIC_FILE="$SETTINGS_DIR/ntfy-topic.txt"
NTFY_SERVER_FILE="$SETTINGS_DIR/ntfy-server.txt"
DEFAULT_NTFY_SERVER="https://ntfy.sh"

if [ -z "$TITLE" ] || [ -z "$MESSAGE" ]; then
  echo "Usage: scripts/sagent-notify.sh \"<title>\" \"<message>\""
  exit 1
fi

if [ ! -s "$NTFY_TOPIC_FILE" ]; then
  echo "ntfy not configured; skipping notification."
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl not available; skipping notification."
  exit 0
fi

TOPIC="$(cat "$NTFY_TOPIC_FILE")"
if [ -s "$NTFY_SERVER_FILE" ]; then
  SERVER="$(cat "$NTFY_SERVER_FILE")"
else
  SERVER="$DEFAULT_NTFY_SERVER"
fi

SERVER="${SERVER%/}"

if ! curl -fsS \
  -H "Title: $TITLE" \
  -H "Priority: 4" \
  -H "Tags: warning,robot" \
  --data-binary "$MESSAGE" \
  "$SERVER/$TOPIC" >/dev/null; then
  echo "ntfy request failed; skipping notification."
  exit 0
fi

echo "ntfy notification sent."
