#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-help}"

WORKSPACE="$HOME/.openclaw/workspace"
RUNS="$WORKSPACE/runs"
RUN_HISTORY="$RUNS/history"
APPROVALS="$WORKSPACE/approvals"
APPROVAL_HISTORY="$APPROVALS/history"

PENDING_FILE="$APPROVALS/pending.json"
PENDING_TASK_FILE="$APPROVALS/pending-task.txt"
DENIED_FILE="$APPROVALS/denied.json"
OUTPUT_FILE="$RUNS/last-output.txt"
STATUS_FILE="$RUNS/last-status.json"
RISK_FILE="$RUNS/last-risk.json"

mkdir -p "$RUNS" "$RUN_HISTORY" "$APPROVALS" "$APPROVAL_HISTORY"

TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"
SESSION_KEY="sagent-approved-$TIMESTAMP"
HISTORY_FILE="$RUN_HISTORY/run-$TIMESTAMP.txt"
HISTORY_STATUS_FILE="$RUN_HISTORY/run-$TIMESTAMP.status.json"
HISTORY_RISK_FILE="$RUN_HISTORY/run-$TIMESTAMP.risk.json"

json_escape() {
  local value="${1:-}"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

json_string_field() {
  local field="$1"
  local file="$2"
  sed -n "s/.*\"$field\": \"\\([^\"]*\\)\".*/\\1/p" "$file" | head -n 1
}

json_number_field() {
  local field="$1"
  local file="$2"
  sed -n "s/.*\"$field\": \\([0-9][0-9]*\\).*/\\1/p" "$file" | head -n 1
}

has_pending() {
  [ -f "$PENDING_FILE" ]
}

pending_task() {
  if [ -f "$PENDING_TASK_FILE" ]; then
    cat "$PENDING_TASK_FILE"
  else
    json_string_field "task" "$PENDING_FILE"
  fi
}

write_status_file() {
  local exit_code="$1"
  cat > "$STATUS_FILE" <<STATUS_EOF
{
  "timestamp": "$TIMESTAMP",
  "session_key": "$SESSION_KEY",
  "task_file": "$PENDING_TASK_FILE",
  "output_file": "$OUTPUT_FILE",
  "history_file": "$HISTORY_FILE",
  "risk_file": "$RISK_FILE",
  "exit_code": $exit_code
}
STATUS_EOF

  cp "$STATUS_FILE" "$HISTORY_STATUS_FILE"
}

write_risk_file() {
  local task="$1"
  local exit_code="$2"
  local security_mode risk_level risk_reason escaped_task escaped_reason
  if [ -f "$PENDING_FILE" ]; then
    security_mode="$(json_string_field "security_mode" "$PENDING_FILE")"
    risk_level="$(json_number_field "risk_level" "$PENDING_FILE")"
    risk_reason="$(json_string_field "risk_reason" "$PENDING_FILE")"
  else
    security_mode="${APPROVED_SECURITY_MODE:-}"
    risk_level="${APPROVED_RISK_LEVEL:-}"
    risk_reason="${APPROVED_RISK_REASON:-}"
  fi
  security_mode="${security_mode:-approved_pending}"
  risk_level="${risk_level:-0}"
  risk_reason="${risk_reason:-human-approved pending task}"
  escaped_task="$(json_escape "$task")"
  escaped_reason="$(json_escape "$risk_reason")"

  cat > "$RISK_FILE" <<RISK_EOF
{
  "timestamp": "$TIMESTAMP",
  "session_key": "$SESSION_KEY",
  "task": "$escaped_task",
  "security_mode": "$security_mode",
  "risk_level": $risk_level,
  "risk_reason": "$escaped_reason",
  "approval_source": "human_approved",
  "exit_code": $exit_code
}
RISK_EOF

  cp "$RISK_FILE" "$HISTORY_RISK_FILE"
}

write_denied_file() {
  local source="$1"
  local previous_pending_file="$2"
  local task_file="$3"
  local escaped_previous escaped_task_file
  escaped_previous="$(json_escape "$previous_pending_file")"
  escaped_task_file="$(json_escape "$task_file")"

  cat > "$DENIED_FILE" <<DENIED_EOF
{
  "timestamp": "$TIMESTAMP",
  "source": "$source",
  "previous_pending_file": "$escaped_previous",
  "task_file": "$escaped_task_file",
  "status": "denied"
}
DENIED_EOF
}

show_help() {
  cat <<HELP_EOF
Usage: scripts/sagent-approval.sh <command>

Commands:
  status   Show the current pending approval.
  approve  Execute the pending task and clear the approval.
  deny     Deny the pending task and clear the approval.
  help     Show this help.
HELP_EOF
}

show_status() {
  if ! has_pending; then
    echo "No pending approval."
    return 0
  fi

  local security_mode risk_level risk_reason
  security_mode="$(json_string_field "security_mode" "$PENDING_FILE")"
  risk_level="$(json_number_field "risk_level" "$PENDING_FILE")"
  risk_reason="$(json_string_field "risk_reason" "$PENDING_FILE")"

  echo "Pending approval found"
  echo "Pending file: $PENDING_FILE"
  echo "Task:"
  pending_task
  if [ -n "$security_mode" ]; then
    echo "Security Mode: $security_mode"
  fi
  if [ -n "$risk_level" ]; then
    echo "Risk Level: $risk_level"
  fi
  if [ -n "$risk_reason" ]; then
    echo "Reason: $risk_reason"
  fi
}

deny_pending() {
  if ! has_pending; then
    echo "No pending approval to deny."
    return 0
  fi

  local denied_json="$APPROVAL_HISTORY/denied-$TIMESTAMP.json"
  local denied_task="$APPROVAL_HISTORY/denied-$TIMESTAMP.txt"

  cp "$PENDING_FILE" "$denied_json"
  if [ -f "$PENDING_TASK_FILE" ]; then
    cp "$PENDING_TASK_FILE" "$denied_task"
  else
    : > "$denied_task"
  fi

  write_denied_file "human_denied" "$denied_json" "$denied_task"
  rm -f "$PENDING_FILE" "$PENDING_TASK_FILE"

  echo "Pending approval denied."
}

approve_pending() {
  if ! has_pending; then
    echo "No pending approval to approve."
    return 0
  fi

  local task risk_level approved_json approved_task
  task="$(pending_task)"
  risk_level="$(json_number_field "risk_level" "$PENDING_FILE")"
  risk_level="${risk_level:-0}"
  APPROVED_SECURITY_MODE="$(json_string_field "security_mode" "$PENDING_FILE")"
  APPROVED_RISK_LEVEL="$risk_level"
  APPROVED_RISK_REASON="$(json_string_field "risk_reason" "$PENDING_FILE")"

  approved_json="$APPROVAL_HISTORY/approved-$TIMESTAMP.json"
  approved_task="$APPROVAL_HISTORY/approved-$TIMESTAMP.txt"

  if [ "$risk_level" -eq 6 ]; then
    local denied_json="$APPROVAL_HISTORY/denied-$TIMESTAMP.json"
    local denied_task="$APPROVAL_HISTORY/denied-$TIMESTAMP.txt"
    cp "$PENDING_FILE" "$denied_json"
    printf '%s\n' "$task" > "$denied_task"
    write_denied_file "risk_6_blocked_on_approve" "$denied_json" "$denied_task"
    rm -f "$PENDING_FILE" "$PENDING_TASK_FILE"
    {
      echo "Denied because pending approval has risk level 6."
      echo "Denied path: $DENIED_FILE"
    } | tee "$OUTPUT_FILE"
    cp "$OUTPUT_FILE" "$HISTORY_FILE"
    write_risk_file "$task" 20
    write_status_file 20
    return 20
  fi

  cp "$PENDING_FILE" "$approved_json"
  printf '%s\n' "$task" > "$approved_task"
  rm -f "$PENDING_FILE" "$PENDING_TASK_FILE"

  echo "Pending approval approved."
  echo "Running OpenClaw..."

  set +e
  openclaw agent \
    --agent main \
    --session-key "$SESSION_KEY" \
    --message "$task" \
    2>&1 | tee "$OUTPUT_FILE"
  local openclaw_exit=${PIPESTATUS[0]}
  set -e

  cp "$OUTPUT_FILE" "$HISTORY_FILE"
  write_risk_file "$task" "$openclaw_exit"
  write_status_file "$openclaw_exit"

  echo ""
  echo "Saved output to: $OUTPUT_FILE"
  echo "Saved history to: $HISTORY_FILE"
  echo "Saved status to: $STATUS_FILE"
  echo "Saved risk to: $RISK_FILE"

  return "$openclaw_exit"
}

case "$COMMAND" in
  status)
    show_status
    ;;
  approve)
    approve_pending
    ;;
  deny)
    deny_pending
    ;;
  help|-h|--help)
    show_help
    ;;
  *)
    echo "Unknown approval command: $COMMAND"
    echo ""
    show_help
    exit 1
    ;;
esac
