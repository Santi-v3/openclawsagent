#!/usr/bin/env bash
set -uo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
HEALTH_DIR="$WORKSPACE/health"
HEALTH_HISTORY="$HEALTH_DIR/history"

mkdir -p "$HEALTH_DIR" "$HEALTH_HISTORY"

TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"
SESSION_KEY="sagent-health-$TIMESTAMP"

OUTPUT_FILE="$HEALTH_DIR/last-health-output.txt"
STATUS_FILE="$HEALTH_DIR/last-health.json"
HISTORY_OUTPUT_FILE="$HEALTH_HISTORY/health-$TIMESTAMP.txt"
HISTORY_STATUS_FILE="$HEALTH_HISTORY/health-$TIMESTAMP.json"

ACTIVE_MODEL="unknown"
STATUS="unhealthy"
REASON="unknown"
EXIT_CODE=1

json_escape() {
  printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])'
}

write_status() {
  cat > "$STATUS_FILE" <<STATUS_EOF
{
  "timestamp": "$(json_escape "$TIMESTAMP")",
  "session_key": "$(json_escape "$SESSION_KEY")",
  "active_model": "$(json_escape "$ACTIVE_MODEL")",
  "status": "$(json_escape "$STATUS")",
  "reason": "$(json_escape "$REASON")",
  "exit_code": $EXIT_CODE,
  "output_file": "$(json_escape "$OUTPUT_FILE")",
  "history_file": "$(json_escape "$HISTORY_OUTPUT_FILE")"
}
STATUS_EOF

  cp "$STATUS_FILE" "$HISTORY_STATUS_FILE"
}

if ! command -v openclaw >/dev/null 2>&1; then
  STATUS="missing_openclaw"
  REASON="openclaw command not found"
  EXIT_CODE=127
  echo "$REASON" | tee "$OUTPUT_FILE"
  cp "$OUTPUT_FILE" "$HISTORY_OUTPUT_FILE"
  write_status
  echo "Sagent health: $STATUS"
  exit "$EXIT_CODE"
fi

ACTIVE_MODEL="$(openclaw models status --plain 2>/dev/null || true)"
if [ -z "$ACTIVE_MODEL" ]; then
  ACTIVE_MODEL="unknown"
fi

echo "Sagent OpenClaw healthcheck"
echo "Session: $SESSION_KEY"
echo "Active model: $ACTIVE_MODEL"
echo "Running ping test..."

set +e
openclaw agent \
  --agent main \
  --session-key "$SESSION_KEY" \
  --message "Antworte exakt mit: pong" \
  2>&1 | tee "$OUTPUT_FILE"
OPENCLAW_EXIT=${PIPESTATUS[0]}
set -e

cp "$OUTPUT_FILE" "$HISTORY_OUTPUT_FILE"

if grep -qi "pong" "$OUTPUT_FILE" && [ "$OPENCLAW_EXIT" -eq 0 ]; then
  STATUS="healthy"
  REASON="openclaw returned pong"
  EXIT_CODE=0
else
  STATUS="unhealthy"
  REASON="openclaw did not return pong or exited with error"
  EXIT_CODE=1
fi

write_status

echo ""
echo "Sagent health: $STATUS"
echo "Reason: $REASON"
echo "Saved health output to: $OUTPUT_FILE"
echo "Saved health status to: $STATUS_FILE"

exit "$EXIT_CODE"
