#!/usr/bin/env bash
set -uo pipefail

TASK="${*:-}"

if [ -z "$TASK" ]; then
  echo "Usage: scripts/sagent-task.sh \"<task>\""
  exit 1
fi

WORKSPACE="$HOME/.openclaw/workspace"
INBOX="$WORKSPACE/inbox"
RUNS="$WORKSPACE/runs"
HISTORY="$RUNS/history"

mkdir -p "$INBOX" "$RUNS" "$HISTORY"

TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"
SESSION_KEY="sagent-bridge-$TIMESTAMP"

TASK_FILE="$INBOX/next-task.txt"
OUTPUT_FILE="$RUNS/last-output.txt"
STATUS_FILE="$RUNS/last-status.json"
HISTORY_FILE="$HISTORY/run-$TIMESTAMP.txt"
HISTORY_STATUS_FILE="$HISTORY/run-$TIMESTAMP.status.json"

cat > "$TASK_FILE" <<TASK_EOF
$TASK
TASK_EOF

echo "Saved task to: $TASK_FILE"
echo "Session: $SESSION_KEY"
echo "Running OpenClaw..."

set +e
openclaw agent \
  --agent main \
  --session-key "$SESSION_KEY" \
  --message "$TASK" \
  2>&1 | tee "$OUTPUT_FILE"
OPENCLAW_EXIT=${PIPESTATUS[0]}
set -e

cat > "$STATUS_FILE" <<STATUS_EOF
{
  "timestamp": "$TIMESTAMP",
  "session_key": "$SESSION_KEY",
  "task_file": "$TASK_FILE",
  "output_file": "$OUTPUT_FILE",
  "history_file": "$HISTORY_FILE",
  "exit_code": $OPENCLAW_EXIT
}
STATUS_EOF

cp "$OUTPUT_FILE" "$HISTORY_FILE"
cp "$STATUS_FILE" "$HISTORY_STATUS_FILE"

echo ""
echo "Saved output to: $OUTPUT_FILE"
echo "Saved history to: $HISTORY_FILE"
echo "Saved status to: $STATUS_FILE"

if [ "$OPENCLAW_EXIT" -ne 0 ]; then
  echo ""
  echo "OpenClaw failed with exit code: $OPENCLAW_EXIT"
  exit "$OPENCLAW_EXIT"
fi
