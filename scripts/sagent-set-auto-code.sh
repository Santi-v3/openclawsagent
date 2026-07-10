#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
SETTINGS_DIR="$HOME/.openclaw/workspace/settings"
ROUTING_FILE="$SETTINGS_DIR/auto-code-routing.txt"

mkdir -p "$SETTINGS_DIR"

if [ ! -f "$ROUTING_FILE" ]; then
  echo "disabled" > "$ROUTING_FILE"
fi

case "$ACTION" in
  enabled|on|true|1)
    echo "enabled" > "$ROUTING_FILE"
    echo "Auto-code routing: enabled"
    echo "Setting was written to $ROUTING_FILE"
    ;;
  disabled|off|false|0)
    echo "disabled" > "$ROUTING_FILE"
    echo "Auto-code routing: disabled"
    echo "Setting was written to $ROUTING_FILE"
    ;;
  status|"")
    CURRENT="$(cat "$ROUTING_FILE")"
    echo "Auto-code routing: $CURRENT"
    echo "Setting stored at: $ROUTING_FILE"
    ;;
  *)
    echo "Usage: scripts/sagent-set-auto-code.sh [enabled|disabled|status]"
    exit 1
    ;;
esac
