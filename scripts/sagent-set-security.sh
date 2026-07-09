#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"

WORKSPACE="$HOME/.openclaw/workspace"
SETTINGS_DIR="$WORKSPACE/settings"
SECURITY_MODE_FILE="$SETTINGS_DIR/security-mode.txt"

mkdir -p "$SETTINGS_DIR"

case "$MODE" in
  always_ask|approve_dangerous|full_access)
    echo "$MODE" > "$SECURITY_MODE_FILE"
    echo "Sagent security mode set to: $MODE"
    ;;
  "")
    if [ -f "$SECURITY_MODE_FILE" ]; then
      echo "Current Sagent security mode: $(cat "$SECURITY_MODE_FILE")"
    else
      echo "Current Sagent security mode: approve_dangerous"
      echo "approve_dangerous" > "$SECURITY_MODE_FILE"
    fi
    ;;
  *)
    echo "Invalid security mode: $MODE"
    echo "Allowed values:"
    echo "  always_ask"
    echo "  approve_dangerous"
    echo "  full_access"
    exit 1
    ;;
esac
