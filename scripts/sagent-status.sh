#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
SETTINGS_DIR="$WORKSPACE/settings"
HEALTH_DIR="$WORKSPACE/health"
RUNS="$WORKSPACE/runs"
APPROVALS="$WORKSPACE/approvals"
OPENCODE_DIR="$WORKSPACE/opencode"
STATUS_DIR="$WORKSPACE/status"
CALLS_DIR="$WORKSPACE/calls"
PENDING_FILE="$APPROVALS/pending.json"

SECURITY_MODE_FILE="$SETTINGS_DIR/security-mode.txt"
AUTO_CODE_FILE="$SETTINGS_DIR/auto-code-routing.txt"
NTFY_TOPIC_FILE="$SETTINGS_DIR/ntfy-topic.txt"
HEALTH_FILE="$HEALTH_DIR/last-health.json"
RISK_FILE="$RUNS/last-risk.json"
COMMAND_FILE="$RUNS/last-command.json"
OPENCODE_STATUS_FILE="$OPENCODE_DIR/last-status.json"
SUMMARY_FILE="$STATUS_DIR/last-status-summary.json"

mkdir -p "$STATUS_DIR"

TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"

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
  if [ -f "$file" ]; then
    sed -n "s/.*\"$field\": \"\\([^\"]*\\)\".*/\\1/p" "$file" | head -n 1
  fi
}

json_number_field() {
  local field="$1"
  local file="$2"
  if [ -f "$file" ]; then
    sed -n "s/.*\"$field\": \\([0-9][0-9]*\\).*/\\1/p" "$file" | head -n 1
  fi
}

json_bool_field() {
  local field="$1"
  local file="$2"
  if [ -f "$file" ]; then
    sed -n "s/.*\"$field\": \\([a-z]*\\).*/\\1/p" "$file" | head -n 1
  fi
}

# --- Gather data ---

# Security Mode
if [ -f "$SECURITY_MODE_FILE" ]; then
  SECURITY_MODE="$(cat "$SECURITY_MODE_FILE")"
else
  SECURITY_MODE="approve_dangerous"
fi

# Auto-Code
if [ -f "$AUTO_CODE_FILE" ]; then
  AUTO_CODE="$(cat "$AUTO_CODE_FILE")"
else
  AUTO_CODE="disabled"
fi

# ntfy status
if [ -f "$NTFY_TOPIC_FILE" ] && [ -s "$NTFY_TOPIC_FILE" ]; then
  NTFY_TOPIC="$(cat "$NTFY_TOPIC_FILE")"
  NTFY_STATUS="configured ($NTFY_TOPIC)"
else
  NTFY_STATUS="not configured"
fi

# OpenClaw Health
if [ -f "$HEALTH_FILE" ]; then
  HEALTH_STATUS="$(json_string_field "status" "$HEALTH_FILE")"
  HEALTH_REASON="$(json_string_field "reason" "$HEALTH_FILE")"
  HEALTH_MODEL="$(json_string_field "active_model" "$HEALTH_FILE")"
else
  HEALTH_STATUS="unknown"
  HEALTH_REASON="no health check run yet"
  HEALTH_MODEL="unknown"
fi

# Active Model (from health check as primary source)
ACTIVE_MODEL="$HEALTH_MODEL"

# Pending Approval
if [ -f "$PENDING_FILE" ]; then
  PENDING_TASK="$(json_string_field "task" "$PENDING_FILE")"
  PENDING_RISK="$(json_number_field "risk_level" "$PENDING_FILE")"
  PENDING_REASON="$(json_string_field "risk_reason" "$PENDING_FILE")"
  PENDING_ACTION="$(json_string_field "requested_action" "$PENDING_FILE")"
  PENDING_STATUS="pending"
else
  PENDING_STATUS="none"
  PENDING_TASK=""
  PENDING_RISK=""
  PENDING_REASON=""
  PENDING_ACTION=""
fi

# Last Risk Level
if [ -f "$RISK_FILE" ]; then
  LAST_RISK_LEVEL="$(json_number_field "risk_level" "$RISK_FILE")"
  LAST_RISK_REASON="$(json_string_field "risk_reason" "$RISK_FILE")"
  LAST_RISK_TASK="$(json_string_field "task" "$RISK_FILE")"
  LAST_RISK_EXIT="$(json_number_field "exit_code" "$RISK_FILE")"
  LAST_RISK_TIMESTAMP="$(json_string_field "timestamp" "$RISK_FILE")"
else
  LAST_RISK_LEVEL=""
  LAST_RISK_REASON=""
  LAST_RISK_TASK=""
  LAST_RISK_EXIT=""
  LAST_RISK_TIMESTAMP=""
fi

# Last Exit-Code (from last-command.json)
if [ -f "$COMMAND_FILE" ]; then
  LAST_COMMAND="$(json_string_field "command" "$COMMAND_FILE")"
  LAST_EXIT_CODE="$(json_number_field "exit_code" "$COMMAND_FILE")"
  LAST_ROUTED_TO="$(json_string_field "routed_to" "$COMMAND_FILE")"
  LAST_COMMAND_TIMESTAMP="$(json_string_field "timestamp" "$COMMAND_FILE")"
else
  LAST_COMMAND=""
  LAST_EXIT_CODE=""
  LAST_ROUTED_TO=""
  LAST_COMMAND_TIMESTAMP=""
fi

# Last Worker (from opencode worker status)
if [ -f "$OPENCODE_STATUS_FILE" ]; then
  LAST_WORKER_MODEL="$(json_string_field "model" "$OPENCODE_STATUS_FILE")"
  LAST_WORKER_EXIT="$(json_number_field "exit_code" "$OPENCODE_STATUS_FILE")"
  LAST_WORKER_TASK="$(json_string_field "task" "$OPENCODE_STATUS_FILE")"
  LAST_WORKER_TIMESTAMP="$(json_string_field "timestamp" "$OPENCODE_STATUS_FILE")"
else
  LAST_WORKER_MODEL=""
  LAST_WORKER_EXIT=""
  LAST_WORKER_TASK=""
  LAST_WORKER_TIMESTAMP=""
fi

# --- Display status ---

echo "╔══════════════════════════════════════════╗"
echo "║         Sagent Runtime Status            ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Timestamp:     $TIMESTAMP"
echo ""
echo " Security Mode:  $SECURITY_MODE"
echo " Auto-Code:      $AUTO_CODE"
echo " ntfy:           $NTFY_STATUS"
echo ""
echo " OpenClaw Health:  ${HEALTH_STATUS:-unknown}"
echo " Active Model:     ${ACTIVE_MODEL:-unknown}"
if [ -n "${HEALTH_REASON:-}" ]; then
  echo " Health Reason:    $HEALTH_REASON"
fi
echo ""
echo " Pending Approval: ${PENDING_STATUS:-none}"
if [ "$PENDING_STATUS" = "pending" ]; then
  echo "   Risk Level:  $PENDING_RISK"
  echo "   Reason:      $PENDING_REASON"
  echo "   Action:      $PENDING_ACTION"
  echo "   Task:        $PENDING_TASK"
fi
echo ""
echo " Last Risk Level:  ${LAST_RISK_LEVEL:-none}"
if [ -n "$LAST_RISK_EXIT" ]; then
  echo "   Task:        $LAST_RISK_TASK"
  echo "   Reason:      $LAST_RISK_REASON"
  echo "   Exit-Code:   $LAST_RISK_EXIT"
  echo "   Timestamp:   $LAST_RISK_TIMESTAMP"
fi
echo ""
echo " Last Exit-Code:   ${LAST_EXIT_CODE:-none}"
if [ -n "$LAST_EXIT_CODE" ]; then
  echo "   Routed To:  $LAST_ROUTED_TO"
  echo "   Command:    $LAST_COMMAND"
  echo "   Timestamp:  $LAST_COMMAND_TIMESTAMP"
fi
echo ""
echo " Last Worker:      ${LAST_WORKER_MODEL:-none}"
if [ -n "$LAST_WORKER_MODEL" ]; then
  echo "   Exit-Code:  $LAST_WORKER_EXIT"
  echo "   Task:       $LAST_WORKER_TASK"
  echo "   Timestamp:  $LAST_WORKER_TIMESTAMP"
fi

# --- Voice Call Status ---

CALL_PENDING_COUNT=0
CALL_ACTIVE_COUNT=0
CALL_HISTORY_COUNT=0
CALL_LAST_STATUS="none"

if [ -d "$CALLS_DIR/pending" ]; then
  CALL_PENDING_COUNT="$(find "$CALLS_DIR/pending" -name 'pending-*.json' 2>/dev/null | wc -l | tr -d ' ')"
fi
if [ -d "$CALLS_DIR/active" ]; then
  CALL_ACTIVE_COUNT="$(find "$CALLS_DIR/active" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')"
fi
if [ -d "$CALLS_DIR/history" ]; then
  CALL_HISTORY_COUNT="$(find "$CALLS_DIR/history" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')"
fi
if [ -f "$CALLS_DIR/last-call.json" ]; then
  CALL_LAST_STATUS="$(json_string_field "status" "$CALLS_DIR/last-call.json")"
fi

echo ""
echo " Voice Calls:"
echo "   Pending:  $CALL_PENDING_COUNT"
echo "   Active:   $CALL_ACTIVE_COUNT"
echo "   History:  $CALL_HISTORY_COUNT"
echo "   Last:     $CALL_LAST_STATUS"

# --- Gemini check ---

GEMINI_CREDENTIALS="not configured"

if [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; then
  GEMINI_CREDENTIALS="configured via environment"
else
  gc_file="$HOME/.openclaw/agents/main/agent/plugins/google/catalog.json"
  if [ -f "$gc_file" ] && jq -e '.providers.google.apiKey | length > 0' "$gc_file" >/dev/null 2>&1; then
    GEMINI_CREDENTIALS="configured in OpenClaw catalog"
  fi
fi

echo ""
echo " Gemini Credentials:  $GEMINI_CREDENTIALS"

# --- Write summary JSON ---

es_sec="$(json_escape "$SECURITY_MODE")"
es_auto="$(json_escape "$AUTO_CODE")"
es_ntfy="$(json_escape "$NTFY_STATUS")"
es_health="$(json_escape "${HEALTH_STATUS:-unknown}")"
es_model="$(json_escape "${ACTIVE_MODEL:-unknown}")"
es_pend="$(json_escape "$PENDING_STATUS")"
es_last_risk="$(json_escape "${LAST_RISK_LEVEL:-none}")"
es_last_exit="$(json_escape "${LAST_EXIT_CODE:-none}")"
es_last_worker="$(json_escape "${LAST_WORKER_MODEL:-none}")"

cat > "$SUMMARY_FILE" <<SUMMARY_EOF
{
  "timestamp": "$TIMESTAMP",
  "security_mode": "$es_sec",
  "auto_code": "$es_auto",
  "ntfy": "$es_ntfy",
  "health_status": "$es_health",
  "active_model": "$es_model",
  "pending_approval": "$es_pend",
  "last_risk_level": $LAST_RISK_LEVEL,
  "last_exit_code": $LAST_EXIT_CODE,
  "last_worker": "$es_last_worker",
  "voice_calls": {
    "pending": $CALL_PENDING_COUNT,
    "active": $CALL_ACTIVE_COUNT,
    "history": $CALL_HISTORY_COUNT
  }
}
SUMMARY_EOF

echo ""
echo "Status summary written to: $SUMMARY_FILE"
exit 0
