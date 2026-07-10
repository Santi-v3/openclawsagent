#!/usr/bin/env bash
set -euo pipefail

TASK="${*:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$TASK" ]; then
  echo "Usage: scripts/sagent-task.sh \"<task>\""
  exit 1
fi

WORKSPACE="$HOME/.openclaw/workspace"
INBOX="$WORKSPACE/inbox"
RUNS="$WORKSPACE/runs"
HISTORY="$RUNS/history"
SETTINGS_DIR="$WORKSPACE/settings"
APPROVALS="$WORKSPACE/approvals"
APPROVAL_HISTORY="$APPROVALS/history"
SECURITY_MODE_FILE="$SETTINGS_DIR/security-mode.txt"
AUTO_CODE_FILE="$SETTINGS_DIR/auto-code-routing.txt"

mkdir -p "$INBOX" "$RUNS" "$HISTORY" "$SETTINGS_DIR" "$APPROVALS" "$APPROVAL_HISTORY"

TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"
SESSION_KEY="sagent-bridge-$TIMESTAMP"

TASK_FILE="$INBOX/next-task.txt"
OUTPUT_FILE="$RUNS/last-output.txt"
STATUS_FILE="$RUNS/last-status.json"
RISK_FILE="$RUNS/last-risk.json"
LAST_COMMAND_FILE="$RUNS/last-command.json"
HISTORY_FILE="$HISTORY/run-$TIMESTAMP.txt"
HISTORY_STATUS_FILE="$HISTORY/run-$TIMESTAMP.status.json"
HISTORY_RISK_FILE="$HISTORY/run-$TIMESTAMP.risk.json"
PENDING_FILE="$APPROVALS/pending.json"
PENDING_TASK_FILE="$APPROVALS/pending-task.txt"
PENDING_HISTORY_FILE="$APPROVAL_HISTORY/pending-$TIMESTAMP.json"
PENDING_HISTORY_TASK_FILE="$APPROVAL_HISTORY/pending-$TIMESTAMP.txt"
DENIED_FILE="$APPROVALS/denied.json"

if [ ! -f "$SECURITY_MODE_FILE" ]; then
  echo "approve_dangerous" > "$SECURITY_MODE_FILE"
fi

SECURITY_MODE="$(cat "$SECURITY_MODE_FILE")"
case "$SECURITY_MODE" in
  always_ask|approve_dangerous|full_access)
    ;;
  *)
    SECURITY_MODE="approve_dangerous"
    echo "$SECURITY_MODE" > "$SECURITY_MODE_FILE"
    ;;
esac

is_coding_task() {
  local task_lower
  task_lower="$(printf '%s' "$TASK" | tr '[:upper:]' '[:lower:]')"

  case "$task_lower" in
    *"erstelle"*|*"schreibe"*|*"ändere"*|*"aendere"*|*"erzeuge"*|*"implementiere"*|*"baue"*|*"fix"*|*"repariere"*|*"bug"*|*"refactor"*|*"test"*|*"pytest"*|*"npm test"*|*"lint"*|*"format"*|*"git commit"*|*"git add"*)
      return 0
      ;;
  esac

  if printf '%s' "$task_lower" | grep -qE '\.(py|sh|js|ts|rs|go|java|c|cpp|h|rb|php|css|html|md|json|yaml|yml|toml|env|gitignore)'; then
    return 0
  fi

  return 1
}

json_escape() {
  local value="${1:-}"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

classify_risk() {
  local task_lower
  task_lower="$(printf '%s' "$TASK" | tr '[:upper:]' '[:lower:]')"

  RISK_LEVEL=1
  RISK_REASON="normal read or inspection task"

  case "$task_lower" in
    *"rm -rf /"*|*"wipe"*|*"format disk"*|*"exfiltrate"*|*"bypass security"*|*"disable firewall"*|*"malware"*|*"steal"*)
      RISK_LEVEL=6
      RISK_REASON="destructive, illegal, or explicitly dangerous action"
      return
      ;;
  esac

  case "$task_lower" in
    *".env"*|*"token"*|*"secret"*|*"private_key"*|*"~/.ssh"*|*"ssh"*|*"password"*|*"passwort"*|*"api key"*|*"keychain"*|*"banking"*|*"wallet"*)
      RISK_LEVEL=5
      RISK_REASON="sensitive data, credentials, or secrets mentioned"
      return
      ;;
  esac

  case "$task_lower" in
    *"git push"*|*"merge"*|*"deploy"*|*"send email"*|*"sende email"*|*"whatsapp"*|*"telegram"*|*"calendar"*|*"kalender"*|*"delete"*|*"löschen"*|*"rm"*|*"install"*|*"brew install"*|*"npm install -g"*|*"account"*|*"payment"*|*"kauf"*|*"buchen"*)
      RISK_LEVEL=4
      RISK_REASON="external effect, deletion, installation, publishing, or account/payment action"
      return
      ;;
  esac

  case "$task_lower" in
    *"npm test"*|*"pytest"*|*"test"*|*"format"*|*"lint"*|*"git status"*|*"git diff"*|*"git commit"*)
      RISK_LEVEL=3
      RISK_REASON="local command, test, formatter, linter, or local git action"
      return
      ;;
  esac

  case "$task_lower" in
    *"erstelle"*|*"schreibe"*|*"ändere"*|*"aendere"*|*"update"*|*"edit"*)
      RISK_LEVEL=2
      RISK_REASON="normal local write or edit task"
      return
      ;;
  esac

  case "$task_lower" in
    *"explain"*|*"erkläre"*|*"erklaere"*|*"plane"*|*"summarize"*|*"zusammenfassen"*)
      RISK_LEVEL=0
      RISK_REASON="reasoning, planning, or summarization task"
      return
      ;;
    *"analysiere"*)
      RISK_LEVEL=0
      RISK_REASON="analysis task without dangerous keywords"
      return
      ;;
  esac

  case "$task_lower" in
    *"lies"*|*"read"*|*"inspect"*|*"prüfe"*|*"pruefe"*|*"schaue"*|*"analysiere"*)
      RISK_LEVEL=1
      RISK_REASON="read, inspect, or analysis task"
      return
      ;;
  esac
}

write_risk_file() {
  local exit_code="$1"
  local escaped_task escaped_reason
  escaped_task="$(json_escape "$TASK")"
  escaped_reason="$(json_escape "$RISK_REASON")"

  cat > "$RISK_FILE" <<RISK_EOF
{
  "timestamp": "$TIMESTAMP",
  "session_key": "$SESSION_KEY",
  "task": "$escaped_task",
  "security_mode": "$SECURITY_MODE",
  "risk_level": $RISK_LEVEL,
  "risk_reason": "$escaped_reason",
  "exit_code": $exit_code
}
RISK_EOF

  cp "$RISK_FILE" "$HISTORY_RISK_FILE"
}

write_status_file() {
  local exit_code="$1"
  cat > "$STATUS_FILE" <<STATUS_EOF
{
  "timestamp": "$TIMESTAMP",
  "session_key": "$SESSION_KEY",
  "task_file": "$TASK_FILE",
  "output_file": "$OUTPUT_FILE",
  "history_file": "$HISTORY_FILE",
  "risk_file": "$RISK_FILE",
  "exit_code": $exit_code
}
STATUS_EOF

  cp "$STATUS_FILE" "$HISTORY_STATUS_FILE"
}

write_pending_approval() {
  local escaped_task escaped_reason
  escaped_task="$(json_escape "$TASK")"
  escaped_reason="$(json_escape "$RISK_REASON")"

  cat > "$PENDING_FILE" <<PENDING_EOF
{
  "timestamp": "$TIMESTAMP",
  "session_key": "$SESSION_KEY",
  "task": "$escaped_task",
  "security_mode": "$SECURITY_MODE",
  "risk_level": $RISK_LEVEL,
  "risk_reason": "$escaped_reason",
  "requested_action": "execute_task",
  "status": "pending"
}
PENDING_EOF

  cat > "$PENDING_TASK_FILE" <<PENDING_TASK_EOF
$TASK
PENDING_TASK_EOF

  cp "$PENDING_FILE" "$PENDING_HISTORY_FILE"
  cp "$PENDING_TASK_FILE" "$PENDING_HISTORY_TASK_FILE"
}

notify_pending_approval() {
  local task_excerpt message
  if [ "$RISK_LEVEL" -eq 5 ]; then
    task_excerpt="Task hidden because risk level is sensitive."
  else
    task_excerpt="$TASK"
    if [ "${#task_excerpt}" -gt 200 ]; then
      task_excerpt="${task_excerpt:0:200}..."
    fi
  fi

  message="$(cat <<MESSAGE_EOF
Security mode: $SECURITY_MODE
Risk: $RISK_LEVEL
Reason: $RISK_REASON
Task: $task_excerpt

Run:
scripts/sagent-approval.sh status
scripts/sagent-approval.sh approve
scripts/sagent-approval.sh deny
MESSAGE_EOF
)"

  "$SCRIPT_DIR/sagent-notify.sh" "Sagent approval required" "$message"
}

write_denied() {
  local escaped_task escaped_reason
  escaped_task="$(json_escape "$TASK")"
  escaped_reason="$(json_escape "$RISK_REASON")"

  cat > "$DENIED_FILE" <<DENIED_EOF
{
  "timestamp": "$TIMESTAMP",
  "session_key": "$SESSION_KEY",
  "task": "$escaped_task",
  "security_mode": "$SECURITY_MODE",
  "risk_level": $RISK_LEVEL,
  "risk_reason": "$escaped_reason",
  "requested_action": "execute_task",
  "status": "denied"
}
DENIED_EOF
}

write_last_command_file() {
  local routed_to="$1"
  local exit_code="$2"
  local escaped_command escaped_routed_to
  escaped_command="$(json_escape "$TASK")"
  escaped_routed_to="$(json_escape "$routed_to")"

  cat > "$LAST_COMMAND_FILE" <<COMMAND_EOF
{
  "timestamp": "$TIMESTAMP",
  "command": "$escaped_command",
  "routed_to": "$escaped_routed_to",
  "exit_code": $exit_code
}
COMMAND_EOF
}

run_internal_command() {
  local routed_to="$1"
  shift

  set +e
  "$@"
  local command_exit=$?
  set -e

  write_last_command_file "$routed_to" "$command_exit"
  exit "$command_exit"
}

show_sagent_help() {
  cat <<HELP_EOF
Sagent commands:
  /set security always_ask|approve_dangerous|full_access
  /security status
  /approval status|approve|deny
  /set ntfy <topic>
  /ntfy --disable
  /auto-code status
  /auto-code enabled|disabled
  /set auto-code enabled|disabled
  /opencode <task>
  /code <task>
  /health
  /openclaw health

Normal tasks without / are sent to OpenClaw.
When auto-code routing is enabled, coding tasks are automatically routed to the OpenCode worker.
HELP_EOF
}

handle_internal_command() {
  case "$TASK" in
    "/help"|"/sagent help")
      show_sagent_help
      write_last_command_file "help" 0
      exit 0
      ;;
    "/set security")
      run_internal_command "scripts/sagent-set-security.sh" "$SCRIPT_DIR/sagent-set-security.sh"
      ;;
    "/set security always_ask"|"/set security approve_dangerous"|"/set security full_access")
      run_internal_command "scripts/sagent-set-security.sh" "$SCRIPT_DIR/sagent-set-security.sh" "${TASK#/set security }"
      ;;
    "/security"|"/security status")
      run_internal_command "scripts/sagent-set-security.sh" "$SCRIPT_DIR/sagent-set-security.sh"
      ;;
    "/approval status"|"/approval approve"|"/approval deny")
      run_internal_command "scripts/sagent-approval.sh" "$SCRIPT_DIR/sagent-approval.sh" "${TASK#/approval }"
      ;;
    "/ntfy"|"/ntfy status")
      run_internal_command "scripts/sagent-set-ntfy.sh" "$SCRIPT_DIR/sagent-set-ntfy.sh"
      ;;
    "/set ntfy --disable"|"/ntfy --disable")
      run_internal_command "scripts/sagent-set-ntfy.sh" "$SCRIPT_DIR/sagent-set-ntfy.sh" "--disable"
      ;;
    "/set ntfy "*)
      run_internal_command "scripts/sagent-set-ntfy.sh" "$SCRIPT_DIR/sagent-set-ntfy.sh" "${TASK#/set ntfy }"
      ;;
    "/ntfy "*)
      run_internal_command "scripts/sagent-set-ntfy.sh" "$SCRIPT_DIR/sagent-set-ntfy.sh" "${TASK#/ntfy }"
      ;;
    "/auto-code"|"/auto-code status")
      run_internal_command "scripts/sagent-set-auto-code.sh" "$SCRIPT_DIR/sagent-set-auto-code.sh" "status"
      ;;
    "/auto-code enabled"|"/set auto-code enabled")
      run_internal_command "scripts/sagent-set-auto-code.sh" "$SCRIPT_DIR/sagent-set-auto-code.sh" "enabled"
      ;;
    "/auto-code disabled"|"/set auto-code disabled")
      run_internal_command "scripts/sagent-set-auto-code.sh" "$SCRIPT_DIR/sagent-set-auto-code.sh" "disabled"
      ;;
    "/opencode "*)
      run_internal_command "scripts/sagent-opencode-worker.sh" "$SCRIPT_DIR/sagent-opencode-worker.sh" "${TASK#/opencode }"
      ;;
    "/code "*)
      run_internal_command "scripts/sagent-opencode-worker.sh" "$SCRIPT_DIR/sagent-opencode-worker.sh" "${TASK#/code }"
      ;;
    "/health"|"/openclaw health")
      run_internal_command "scripts/sagent-healthcheck.sh" "$SCRIPT_DIR/sagent-healthcheck.sh"
      ;;
    /*)
      echo "Unknown Sagent command: $TASK"
      echo "Run /help for available commands."
      write_last_command_file "unknown" 2
      exit 2
      ;;
  esac
}

handle_internal_command

cat > "$TASK_FILE" <<TASK_EOF
$TASK
TASK_EOF

classify_risk

echo "Saved task to: $TASK_FILE"
echo "Session: $SESSION_KEY"
echo "Security Mode: $SECURITY_MODE"
echo "Risk Level: $RISK_LEVEL"
echo "Reason: $RISK_REASON"

if [ "$RISK_LEVEL" -eq 6 ]; then
  {
    echo "Denied because risk level is 6."
    echo "Security Mode: $SECURITY_MODE"
    echo "Risk Level: $RISK_LEVEL"
    echo "Reason: $RISK_REASON"
    echo "Denied path: $DENIED_FILE"
  } | tee "$OUTPUT_FILE"
  cp "$OUTPUT_FILE" "$HISTORY_FILE"
  write_denied
  write_risk_file 20
  write_status_file 20
  echo "Saved risk to: $RISK_FILE"
  echo "Saved denied request to: $DENIED_FILE"
  exit 20
fi

if [ "$SECURITY_MODE" = "always_ask" ] || { [ "$SECURITY_MODE" = "approve_dangerous" ] && [ "$RISK_LEVEL" -ge 4 ]; }; then
  {
    if [ "$SECURITY_MODE" = "always_ask" ]; then
      echo "Approval required because security mode is always_ask."
    else
      echo "Approval required because risk level is $RISK_LEVEL."
    fi
    echo "Security Mode: $SECURITY_MODE"
    echo "Risk Level: $RISK_LEVEL"
    echo "Reason: $RISK_REASON"
    echo "Pending approval path: $PENDING_FILE"
  } | tee "$OUTPUT_FILE"
  cp "$OUTPUT_FILE" "$HISTORY_FILE"
  write_pending_approval
  notify_pending_approval
  write_risk_file 10
  write_status_file 10
  echo "Saved risk to: $RISK_FILE"
  echo "Saved pending approval to: $PENDING_FILE"
  echo "Saved pending task to: $PENDING_TASK_FILE"
  exit 10
fi

AUTO_CODE="disabled"
if [ -f "$AUTO_CODE_FILE" ]; then
  AUTO_CODE="$(cat "$AUTO_CODE_FILE")"
fi

if [ "$AUTO_CODE" = "enabled" ] && is_coding_task; then
  echo "Auto-code routing: enabled — routing coding task to OpenCode worker..."
  echo ""

  set +e
  "$SCRIPT_DIR/sagent-opencode-worker.sh" "$TASK" 2>&1 | tee "$OUTPUT_FILE"
  OPENCLAW_EXIT=${PIPESTATUS[0]}
  set -e

  cp "$OUTPUT_FILE" "$HISTORY_FILE"
  write_risk_file "$OPENCLAW_EXIT"
  write_status_file "$OPENCLAW_EXIT"

  echo ""
  echo "Saved output to: $OUTPUT_FILE"
  echo "Saved history to: $HISTORY_FILE"
  echo "Saved status to: $STATUS_FILE"
  echo "Saved risk to: $RISK_FILE"

  if [ "$OPENCLAW_EXIT" -ne 0 ]; then
    echo ""
    echo "OpenCode worker failed with exit code: $OPENCLAW_EXIT"
    exit "$OPENCLAW_EXIT"
  fi
  exit "$OPENCLAW_EXIT"
fi

echo "Running OpenClaw..."

set +e
openclaw agent \
  --agent main \
  --session-key "$SESSION_KEY" \
  --message "$TASK" \
  2>&1 | tee "$OUTPUT_FILE"
OPENCLAW_EXIT=${PIPESTATUS[0]}
set -e

cp "$OUTPUT_FILE" "$HISTORY_FILE"
write_risk_file "$OPENCLAW_EXIT"
write_status_file "$OPENCLAW_EXIT"

echo ""
echo "Saved output to: $OUTPUT_FILE"
echo "Saved history to: $HISTORY_FILE"
echo "Saved status to: $STATUS_FILE"
echo "Saved risk to: $RISK_FILE"

if [ "$OPENCLAW_EXIT" -ne 0 ]; then
  echo ""
  echo "OpenClaw failed with exit code: $OPENCLAW_EXIT"
  exit "$OPENCLAW_EXIT"
fi
