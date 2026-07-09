#!/usr/bin/env bash
set -euo pipefail

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
TASK_FILE="$INBOX/next-task.txt"
OUTPUT_FILE="$RUNS/last-output.txt"
HISTORY_FILE="$HISTORY/run-$TIMESTAMP.txt"

cat > "$TASK_FILE" <<TASK_EOF
$TASK
TASK_EOF

echo "Saved task to: $TASK_FILE"
echo "Running OpenClaw..."

openclaw agent \
  --agent main \
  --session-key "sagent-bridge-$TIMESTAMP" \
  --message "$TASK" \
  | tee "$OUTPUT_FILE"

cp "$OUTPUT_FILE" "$HISTORY_FILE"

echo ""
echo "Saved output to: $OUTPUT_FILE"
echo "Saved history to: $HISTORY_FILE"
