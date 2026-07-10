#!/usr/bin/env bash
set -euo pipefail

TOPIC="${1:-}"

WORKSPACE="$HOME/.openclaw/workspace"
SETTINGS_DIR="$WORKSPACE/settings"
NTFY_TOPIC_FILE="$SETTINGS_DIR/ntfy-topic.txt"
NTFY_SERVER_FILE="$SETTINGS_DIR/ntfy-server.txt"
DEFAULT_NTFY_SERVER="https://ntfy.sh"

mkdir -p "$SETTINGS_DIR"

ntfy_server() {
  if [ -s "$NTFY_SERVER_FILE" ]; then
    cat "$NTFY_SERVER_FILE"
  else
    echo "$DEFAULT_NTFY_SERVER"
  fi
}

case "$TOPIC" in
  "")
    if [ -s "$NTFY_TOPIC_FILE" ]; then
      echo "ntfy topic: $(cat "$NTFY_TOPIC_FILE")"
      echo "ntfy server: $(ntfy_server)"
    else
      echo "ntfy topic: not configured"
    fi
    ;;
  --disable)
    rm -f "$NTFY_TOPIC_FILE"
    echo "ntfy topic disabled"
    ;;
  *)
    printf '%s\n' "$TOPIC" > "$NTFY_TOPIC_FILE"
    echo "ntfy topic: $TOPIC"
    echo "ntfy server: $(ntfy_server)"
    ;;
esac
