#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-help}"
shift 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$HOME/.openclaw/workspace"
CALLS_DIR="$WORKSPACE/calls"
PENDING_DIR="$CALLS_DIR/pending"
ACTIVE_DIR="$CALLS_DIR/active"
HISTORY_DIR="$CALLS_DIR/history"
LAST_CALL_FILE="$CALLS_DIR/last-call.json"
MOCK_MODE="mock"

mkdir -p "$PENDING_DIR" "$ACTIVE_DIR" "$HISTORY_DIR"

TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"

mask_phone() {
  local num="$1"
  if [[ "$num" =~ ^\+[1-9][0-9]{6,14}$ ]]; then
    local len="${#num}"
    local prefix="${num:0:len-4}"
    local suffix="${num: -4}"
    local masked_prefix="${prefix//[0-9]/*}"
    echo "${masked_prefix}${suffix}"
  else
    echo "$num"
  fi
}

validate_e164() {
  local num="$1"
  [[ "$num" =~ ^\+[1-9][0-9]{6,14}$ ]]
}

validate_language() {
  local lang="$1"
  [[ "$lang" =~ ^[a-z]{2}(-[A-Z]{2})?$ ]]
}

validate_goal() {
  local goal="$1"
  [ -n "$goal" ] && [ "${#goal}" -ge 3 ] && [ "${#goal}" -le 500 ]
}

show_help() {
  cat <<HELP_EOF
Usage: scripts/sagent-call.sh <command> [options]

Commands:
  setup                           Run safe setup checks.
  check                           Check voice call system status.
  gemini-check                    Check Gemini Live voice provider readiness.
  twilio-check                    Check Twilio telephony provider readiness.
  mock <number> --language <code> --goal <text>   Simulate a mock call.
  request <number> --language <code> --goal <text> Create a pending call request.
  execute-pending                 Execute a pending call (via approval system only).
  status                          Show current call status.
  last                            Show the last call result (German default).
  transcript                      Show the last call transcript.
  summarize                       Summarize the last call.
  help                            Show this help.

Options:
  --language <code>   Language code (e.g. de, en, fr, es-MX).
  --goal <text>       Conversation goal (3-500 chars).

Mock mode: Uses the mock provider only. No real calls are made.
Request mode: Creates a pending job only. No real calls are started.

Configuration files in config/:
  voice-call-mock.example.json5                 Mock provider example config
  voice-call-gemini-live.example.json5          Gemini Live example config
  voice-call-twilio-gemini.example.json5        Twilio + Gemini Live example config
  voice-call-system-prompt.txt                  System prompt for voice calls
HELP_EOF
}

cmd_setup() {
  echo "Sagent Call Setup"
  echo "================="
  echo ""
  echo "Workspace directories:"
  echo "  Pending:  $PENDING_DIR"
  echo "  Active:   $ACTIVE_DIR"
  echo "  History:  $HISTORY_DIR"
  echo "  Last:     $LAST_CALL_FILE"
  echo ""
  echo "Checking prerequisites..."

  local has_openclaw=false
  if command -v openclaw &>/dev/null; then
    has_openclaw=true
    echo "  openclaw binary:       found ($(command -v openclaw))"
  else
    echo "  openclaw binary:       NOT found (optional, needed for check)"
  fi

  echo "  Calls workspace dirs:  OK"
  echo "  Script location:       $SCRIPT_DIR/sagent-call.sh"

  local mock_example="$SCRIPT_DIR/../config/voice-call-mock.example.json5"
  if [ -f "$mock_example" ]; then
    echo "  mock example config:   $mock_example"
  fi

  local gemini_example="$SCRIPT_DIR/../config/voice-call-gemini-live.example.json5"
  if [ -f "$gemini_example" ]; then
    echo "  gemini example config: $gemini_example"
  fi

  local twilio_example="$SCRIPT_DIR/../config/voice-call-twilio-gemini.example.json5"
  if [ -f "$twilio_example" ]; then
    echo "  twilio example config: $twilio_example"
  fi

  local system_prompt="$SCRIPT_DIR/../config/voice-call-system-prompt.txt"
  if [ -f "$system_prompt" ]; then
    echo "  system prompt:         $system_prompt"
  fi

  echo ""
  if $has_openclaw; then
    local oc_version
    oc_version="$(openclaw --version 2>/dev/null || echo "unknown")"
    echo "  openclaw version:      $oc_version"
  fi
  echo ""
  echo "Setup check complete. No real calls configured."
  echo "To test the voice call system, run: scripts/sagent-call.sh check"
}

cmd_check() {
  if command -v openclaw &>/dev/null; then
    echo "Running: openclaw voicecall setup --json"
    echo ""
    set +e
    openclaw voicecall setup --json 2>&1
    local oc_exit=$?
    set -e
    echo ""
    if [ "$oc_exit" -eq 0 ]; then
      echo "Voice call system check passed."
    else
      echo "Voice call system check returned exit code $oc_exit."
    fi
  else
    echo "openclaw not found. Run 'scripts/sagent-call.sh setup' for environment info."
    echo "Cannot run voicecall check without openclaw binary."
    return 1
  fi
}

cmd_gemini_check() {
  echo "Gemini Live Voice Check"
  echo "======================="
  echo ""

  local oc_available=false
  if command -v openclaw &>/dev/null; then
    oc_available=true
  fi

  if ! $oc_available; then
    echo "  openclaw:            NOT found"
    echo "  Status:              FAIL - openclaw required for voice calls"
    return 1
  fi

  echo "  openclaw:            found ($(command -v openclaw))"
  echo ""

  set +e
  local setup_json
  setup_json="$(openclaw voicecall setup --json 2>&1)"
  local oc_exit=$?
  set -e

  if [ "$oc_exit" -ne 0 ]; then
    echo "  voicecall plugin:    FAIL"
    echo "  openclaw voicecall setup returned exit code $oc_exit"
    return 1
  fi

  local current_provider
  current_provider="$(echo "$setup_json" | grep -A2 '"id": "provider"' | grep '"message"' | sed 's/.*Provider configured: \([^"]*\).*/\1/' | head -1)"
  echo "  current provider:    ${current_provider:-unknown}"

  local plugin_ok
  plugin_ok="$(echo "$setup_json" | grep -A2 '"id": "plugin-enabled"' | grep '"ok"' | sed 's/.*"ok": \([^,}]*\).*/\1/' | tr -d ' ')"
  if [ "$plugin_ok" = "true" ]; then
    echo "  voicecall plugin:    enabled"
  else
    echo "  voicecall plugin:    DISABLED"
  fi

  echo ""

  local gemini_config_file="$SCRIPT_DIR/../config/voice-call-gemini-live.json"
  local gemini_example_file="$SCRIPT_DIR/../config/voice-call-gemini-live.example.json5"
  if [ -f "$gemini_config_file" ]; then
    echo "  gemini config:       found (voice-call-gemini-live.json)"
  else
    echo "  gemini config:      NOT FOUND (example at voice-call-gemini-live.example.json5)"
    if [ -f "$gemini_example_file" ]; then
      echo "                       -> copy example to voice-call-gemini-live.json to configure"
    fi
  fi

  local mock_config_file="$SCRIPT_DIR/../config/voice-call-mock.json"
  local mock_example_file="$SCRIPT_DIR/../config/voice-call-mock.example.json5"
  if [ -f "$mock_config_file" ]; then
    echo "  mock config:         found (voice-call-mock.json)"
  else
    if [ -f "$mock_example_file" ]; then
      echo "  mock config:        example exists (voice-call-mock.example.json5)"
      echo "                       -> copy to voice-call-mock.json for custom mock settings"
    else
      echo "  mock config:        NOT FOUND (no example or config)"
    fi
  fi

  local system_prompt_file="$SCRIPT_DIR/../config/voice-call-system-prompt.txt"
  if [ -f "$system_prompt_file" ]; then
    echo "  system prompt:       found (voice-call-system-prompt.txt)"
  else
    echo "  system prompt:      NOT FOUND"
  fi

  echo ""
  # --- safe credential check (never leaks key values) ---
  local google_catalog="$HOME/.openclaw/agents/main/agent/plugins/google/catalog.json"
  local credential_source="none"

  if [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; then
    credential_source="env"
  elif [ -f "$google_catalog" ] && jq -e '.providers.google.apiKey | length > 0' "$google_catalog" >/dev/null 2>&1; then
    credential_source="catalog"
  fi

  case "$credential_source" in
    env)     echo "  Gemini Credentials: configured via environment" ;;
    catalog) echo "  Gemini Credentials: configured in OpenClaw catalog" ;;
    *)       echo "  Gemini Credentials: not configured" ;;
  esac

  local has_creds=false
  [ "$credential_source" != "none" ] && has_creds=true

  local google_realtime_available=false
  [ "${current_provider:-}" = "google-realtime" ] && google_realtime_available=true

  echo "  Credentials vorhanden:             $(if $has_creds; then echo ja; else echo nein; fi)"
  echo "  Google-Realtime-Provider verfuegbar: $(if $google_realtime_available; then echo ja; else echo nein; fi)"
  echo "  Gemini-Live-Konfiguration vorbereitet: $(if [ -f "$gemini_config_file" ]; then echo ja; else echo nein; fi)"
  echo "  Gemini Live getestet:              nein"

  echo ""
  echo "Gemini Live check complete."
  echo "Provider remains: mock (no changes made)"
}

cmd_twilio_check() {
  echo "Twilio Provider Check"
  echo "====================="
  echo ""

  local has_sid=false
  local has_token=false
  local has_from=false

  if [ -n "${TWILIO_ACCOUNT_SID:-}" ]; then
    has_sid=true
  fi
  if [ -n "${TWILIO_AUTH_TOKEN:-}" ]; then
    has_token=true
  fi
  if [ -n "${TWILIO_FROM_NUMBER:-}" ]; then
    has_from=true
  fi

  local sid_status="not configured"
  local token_status="not configured"
  local from_status="not configured"

  $has_sid   && sid_status="configured"
  $has_token && token_status="configured"
  $has_from  && from_status="configured"

  echo "  Twilio Credentials:"
  echo "    Account SID:       $sid_status"
  echo "    Auth Token:        $token_status"
  echo "    From Number:       $from_status"
  echo ""

  local all_configured=false
  $has_sid && $has_token && $has_from && all_configured=true

  echo "  Credentials:       $($all_configured && echo "configured" || echo "not configured")"

  local has_webhook=false
  if [ -n "${TWILIO_PUBLIC_URL:-}" ]; then
    has_webhook=true
  fi
  echo "  Webhook:           $($has_webhook && echo "configured" || echo "not configured")"

  local has_voice_plugin=false
  if command -v openclaw &>/dev/null; then
    local plugin_check
    plugin_check="$(openclaw voicecall setup --json 2>/dev/null || true)"
    if echo "$plugin_check" | grep -q '"ok": true'; then
      has_voice_plugin=true
    fi
  fi
  echo "  Voice Plugin:      $($has_voice_plugin && echo "installed" || echo "not installed")"

  local google_configured=false
  if [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; then
    google_configured=true
  fi
  echo "  Google Realtime:   $($google_configured && echo "registered" || echo "not registered")"

  local live_config_file="$SCRIPT_DIR/../config/voice-call-twilio-gemini.json"
  local live_config_prepared=false
  [ -f "$live_config_file" ] && live_config_prepared=true
  echo "  Live Config:       $($live_config_prepared && echo "prepared" || echo "not prepared")"

  echo "  Real Call Test:    not performed"
  echo ""
  echo "  No real call has been made."
  echo "  No credentials have been displayed."
  echo ""
  echo "Twilio check complete."
  echo "Provider remains: mock (no changes made)"
}

cmd_mock() {
  local number=""
  local language=""
  local goal=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --language) language="$2"; shift 2 ;;
      --goal) goal="$2"; shift 2 ;;
      --yes)
        echo "ERROR: --yes is not allowed in mock mode."
        return 1
        ;;
      --*)
        echo "ERROR: Unknown option: $1"
        return 1
        ;;
      *)
        if [ -z "$number" ]; then
          number="$1"
        else
          echo "ERROR: Unexpected argument: $1"
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$number" ]; then
    echo "ERROR: Phone number is required."
    echo "Usage: scripts/sagent-call.sh mock <number> --language <code> --goal <text>"
    return 1
  fi

  if ! validate_e164 "$number"; then
    echo "ERROR: Invalid phone number. Must be E.164 format (e.g. +491234567890)."
    return 1
  fi

  if [ -z "$language" ]; then
    echo "ERROR: --language is required."
    return 1
  fi

  if ! validate_language "$language"; then
    echo "ERROR: Invalid language code. Must be like 'de', 'en', 'fr', 'es-MX'."
    return 1
  fi

  if [ -z "$goal" ]; then
    echo "ERROR: --goal is required."
    return 1
  fi

  if ! validate_goal "$goal"; then
    echo "ERROR: Goal must be between 3 and 500 characters."
    return 1
  fi

  local masked
  masked="$(mask_phone "$number")"
  echo "Mock Call Request"
  echo "================="
  echo "  Number:   $masked"
  echo "  Language: $language"
  echo "  Goal:     $goal"
  echo "  Provider: mock"
  echo ""

  mkdir -p "$ACTIVE_DIR"
  local call_file="$ACTIVE_DIR/call-$TIMESTAMP.json"
  cat > "$call_file" <<CALL_EOF
{
  "timestamp": "$TIMESTAMP",
  "number": "$number",
  "language": "$language",
  "goal": "$goal",
  "provider": "mock",
  "status": "simulated",
  "type": "mock",
  "real_call": false
}
CALL_EOF

  cp "$call_file" "$LAST_CALL_FILE"

  echo "Running mock call simulation..."
  echo ""
  echo "  [SIMULATED] Dialing $masked ..."
  sleep 0.5
  echo "  [SIMULATED] Language: $language"
  echo "  [SIMULATED] Goal: $goal"
  echo "  [SIMULATED] Call connected (mock)."
  sleep 0.3
  echo "  [SIMULATED] Conversation completed."
  echo "  [SIMULATED] Call duration: 00:00:42"
  echo ""

  local transcript_file="$ACTIVE_DIR/call-$TIMESTAMP-transcript.txt"
  cat > "$transcript_file" <<TRANS_EOF
=== Mock Call Transcript ===
Timestamp: $TIMESTAMP
Number: $masked
Language: $language
Goal: $goal
Provider: mock

[SIMULATED] Call started.
[SIMULATED] Greeting exchanged.
[SIMULATED] Goal discussed: $goal
[SIMULATED] Questions answered.
[SIMULATED] Call completed successfully.
=== End of Transcript ===
TRANS_EOF

  local summary_file="$ACTIVE_DIR/call-$TIMESTAMP-summary.txt"
  cat > "$summary_file" <<SUM_EOF
Mock Call Summary
=================
Number: $masked
Language: $language
Goal: $goal
Duration: 00:00:42
Outcome: Success (simulated)
Notes: This was a mock call. No real call was made.
SUM_EOF

  echo "Mock call complete."
  echo "  Call file:     $call_file"
  echo "  Transcript:    $transcript_file"
  echo "  Summary:       $summary_file"
}

cmd_request() {
  local number=""
  local language=""
  local goal=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --language) language="$2"; shift 2 ;;
      --goal) goal="$2"; shift 2 ;;
      --yes)
        echo "ERROR: --yes is not allowed. Real calls require manual approval."
        return 1
        ;;
      --*)
        echo "ERROR: Unknown option: $1"
        return 1
        ;;
      *)
        if [ -z "$number" ]; then
          number="$1"
        else
          echo "ERROR: Unexpected argument: $1"
          return 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$number" ]; then
    echo "ERROR: Phone number is required."
    echo "Usage: scripts/sagent-call.sh request <number> --language <code> --goal <text>"
    return 1
  fi

  if ! validate_e164 "$number"; then
    echo "ERROR: Invalid phone number. Must be E.164 format (e.g. +491234567890)."
    return 1
  fi

  if [ -z "$language" ]; then
    echo "ERROR: --language is required."
    return 1
  fi

  if ! validate_language "$language"; then
    echo "ERROR: Invalid language code. Must be like 'de', 'en', 'fr', 'es-MX'."
    return 1
  fi

  if [ -z "$goal" ]; then
    echo "ERROR: --goal is required."
    return 1
  fi

  if ! validate_goal "$goal"; then
    echo "ERROR: Goal must be between 3 and 500 characters."
    return 1
  fi

  local masked
  masked="$(mask_phone "$number")"
  echo "Pending Call Request"
  echo "===================="
  echo "  Number:   $masked"
  echo "  Language: $language"
  echo "  Goal:     $goal"
  echo ""

  local pending_file="$PENDING_DIR/pending-$TIMESTAMP.json"
  cat > "$pending_file" <<PENDING_EOF
{
  "timestamp": "$TIMESTAMP",
  "number": "$number",
  "language": "$language",
  "goal": "$goal",
  "status": "pending",
  "type": "voice_call_request"
}
PENDING_EOF

  local summary_json_file="$PENDING_DIR/pending-$TIMESTAMP-summary.json"
  cat > "$summary_json_file" <<JSON_EOF
{
  "phone": "$number",
  "language": "$language",
  "goal": "$goal",
  "created": "$TIMESTAMP",
  "status": "pending",
  "approval_required": true
}
JSON_EOF

  echo "Pending call request created."
  echo "  Pending file:         $pending_file"
  echo "  Summary-JSON:         $summary_json_file"
  echo ""
  echo "  No real call has been made."
  echo "  Manual approval is required before this call can be executed."
  echo "  The call request is stored locally for review."
}

cmd_status() {
  echo "Call Status"
  echo "==========="
  echo ""

  local pending_count=0
  local active_count=0
  local history_count=0
  local approval_pending="nein"

  if [ -d "$PENDING_DIR" ]; then
    pending_count="$(find "$PENDING_DIR" -name 'pending-*.json' ! -name '*-summary.json' 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$pending_count" -gt 0 ]; then
      approval_pending="ja ($pending_count ausstehend)"
    fi
  fi

  if [ -d "$ACTIVE_DIR" ]; then
    active_count="$(find "$ACTIVE_DIR" -name '*.json' ! -name '*-transcript.json' ! -name '*-summary.json' 2>/dev/null | wc -l | tr -d ' ')"
  fi

  if [ -d "$HISTORY_DIR" ]; then
    history_count="$(find "$HISTORY_DIR" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')"
  fi

  echo "  Provider:         mock"
  echo "  Mode:             $MOCK_MODE"
  echo "  Pending calls:    $pending_count"
  echo "  Active calls:     $active_count"
  echo "  History calls:    $history_count"
  echo "  Pending approval: $approval_pending"
  echo ""

  if [ "$pending_count" -gt 0 ]; then
    echo "Pending files:"
    find "$PENDING_DIR" -name 'pending-*.json' ! -name '*-summary.json' 2>/dev/null | sort | while read -r pf; do
      local pf_number pf_lang pf_goal pf_ts
      pf_ts="$(sed -n 's/.*"timestamp": "\([^"]*\)".*/\1/p' "$pf" | head -1)"
      pf_number="$(sed -n 's/.*"number": "\([^"]*\)".*/\1/p' "$pf" | head -1)"
      pf_lang="$(sed -n 's/.*"language": "\([^"]*\)".*/\1/p' "$pf" | head -1)"
      pf_goal="$(sed -n 's/.*"goal": "\([^"]*\)".*/\1/p' "$pf" | head -1)"
      printf "    [%s] %s, lang=%s, goal=%s\n" "$pf_ts" "$(mask_phone "$pf_number")" "$pf_lang" "$pf_goal"
    done
  fi

  if [ -f "$LAST_CALL_FILE" ]; then
    local last_ts
    last_ts="$(sed -n 's/.*"timestamp": "\([^"]*\)".*/\1/p' "$LAST_CALL_FILE" | head -1)"
    local transcript_file="$ACTIVE_DIR/call-$last_ts-transcript.txt"
    local summary_file="$ACTIVE_DIR/call-$last_ts-summary.txt"
    local summary_json_file="$ACTIVE_DIR/call-$last_ts-summary.json"

    echo ""
    echo "Last transcript:"
    if [ -f "$transcript_file" ]; then
      echo "  $transcript_file"
    else
      echo "  nicht vorhanden"
    fi
    echo "Last summary:"
    if [ -f "$summary_file" ]; then
      echo "  $summary_file"
    else
      echo "  nicht vorhanden"
    fi
    if [ -f "$summary_json_file" ]; then
      echo "  (JSON): $summary_json_file"
    fi
  fi
}

cmd_last() {
  if [ ! -f "$LAST_CALL_FILE" ]; then
    echo "No last call data found at $LAST_CALL_FILE"
    return 0
  fi

  local ts number lang goal status provider
  ts="$(sed -n 's/.*"timestamp": "\([^"]*\)".*/\1/p' "$LAST_CALL_FILE" | head -1)"
  number="$(sed -n 's/.*"number": "\([^"]*\)".*/\1/p' "$LAST_CALL_FILE" | head -1)"
  lang="$(sed -n 's/.*"language": "\([^"]*\)".*/\1/p' "$LAST_CALL_FILE" | head -1)"
  goal="$(sed -n 's/.*"goal": "\([^"]*\)".*/\1/p' "$LAST_CALL_FILE" | head -1)"
  status="$(sed -n 's/.*"status": "\([^"]*\)".*/\1/p' "$LAST_CALL_FILE" | head -1)"
  provider="$(sed -n 's/.*"provider": "\([^"]*\)".*/\1/p' "$LAST_CALL_FILE" | head -1)"

  echo "Letzter Anruf (deutsche Zusammenfassung)"
  echo "========================================"
  echo "  Zeitstempel:  ${ts:-N/A}"
  echo "  Rufnummer:    $(mask_phone "${number:-N/A}")"
  echo "  Sprache:      ${lang:-N/A}"
  echo "  Ziel:         ${goal:-N/A}"
  echo "  Status:       ${status:-N/A}"
  echo "  Anbieter:     ${provider:-N/A}"
}

cmd_transcript() {
  if [ ! -f "$LAST_CALL_FILE" ]; then
    echo "No last call data found. Run a mock or request first."
    return 0
  fi

  local ts
  ts="$(sed -n 's/.*"timestamp": "\([^"]*\)".*/\1/p' "$LAST_CALL_FILE" | head -1)"

  local transcript_file="$ACTIVE_DIR/call-$ts-transcript.txt"

  if [ -f "$transcript_file" ]; then
    echo "Transcript for call $ts"
    echo "======================="
    echo ""
    cat "$transcript_file"
  else
    echo "No transcript file found at:"
    echo "  $transcript_file"
    echo ""
    echo "Note: Only mock calls currently produce transcripts."
    echo "Pending call requests have no transcript yet."
  fi
}

cmd_execute_pending() {
  if [ -z "${SAGENT_EXECUTE_PENDING:-}" ]; then
    echo "ERROR: execute-pending darf nur ueber das Approval-System gestartet werden."
    return 1
  fi

  local pending_file=""
  pending_file="$(find "$PENDING_DIR" -name '*.json' 2>/dev/null | sort | tail -1)"

  if [ -z "$pending_file" ]; then
    echo "ERROR: Keine ausstehenden Anrufe im Pending-Verzeichnis gefunden."
    return 1
  fi

  local number language goal ts
  ts="$(sed -n 's/.*"timestamp": "\([^"]*\)".*/\1/p' "$pending_file" | head -1)"
  number="$(sed -n 's/.*"number": "\([^"]*\)".*/\1/p' "$pending_file" | head -1)"
  language="$(sed -n 's/.*"language": "\([^"]*\)".*/\1/p' "$pending_file" | head -1)"
  goal="$(sed -n 's/.*"goal": "\([^"]*\)".*/\1/p' "$pending_file" | head -1)"

  if [ -z "$number" ] || [ -z "$language" ] || [ -z "$goal" ]; then
    echo "ERROR: Ungueltige Pending-Datei: $pending_file"
    return 1
  fi

  local masked
  masked="$(mask_phone "$number")"
  echo "Ausstehenden Anruf ausfuehren (genehmigt)"
  echo "=========================================="
  echo "  Nummer:   $masked"
  echo "  Sprache:  $language"
  echo "  Ziel:     $goal"
  echo "  Anbieter: mock"
  echo ""

  mkdir -p "$ACTIVE_DIR"
  local call_file="$ACTIVE_DIR/call-$ts.json"
  cat > "$call_file" <<CALL_EOF
{
  "timestamp": "$ts",
  "number": "$number",
  "language": "$language",
  "goal": "$goal",
  "provider": "mock",
  "status": "simulated",
  "type": "execute_pending",
  "real_call": false,
  "approval_required": true
}
CALL_EOF

  cp "$call_file" "$LAST_CALL_FILE"

  local history_file="$HISTORY_DIR/pending-$ts.json"
  mv "$pending_file" "$history_file"

  echo "Simuliere Anruf..."
  echo ""
  echo "  [SIMULIERT] Waehle $masked ..."
  sleep 0.5
  echo "  [SIMULIERT] Sprache: $language"
  echo "  [SIMULIERT] Ziel: $goal"
  echo "  [SIMULIERT] Verbunden (mock)."
  sleep 0.3
  echo "  [SIMULIERT] Gespraech beendet."
  echo "  [SIMULIERT] Dauer: 00:00:42"
  echo ""

  local transcript_file="$ACTIVE_DIR/call-$ts-transcript.txt"
  cat > "$transcript_file" <<TRANS_EOF
=== Mock Call Transcript ===
Timestamp: $ts
Number: $masked
Language: $language
Goal: $goal
Provider: mock
Approval: Required (genehmigt)

[SIMULATED] Call started.
[SIMULATED] Greeting exchanged.
[SIMULATED] Goal discussed: $goal
[SIMULATED] Questions answered.
[SIMULATED] Call completed successfully.
=== End of Transcript ===
TRANS_EOF

  local summary_file="$ACTIVE_DIR/call-$ts-summary.txt"
  cat > "$summary_file" <<SUM_EOF
Mock Call Summary
=================
Number: $masked
Language: $language
Goal: $goal
Duration: 00:00:42
Outcome: Success (simulated, approved)
Notes: Dieser Anruf wurde ueber das Approval-System genehmigt.
SUM_EOF

  local summary_json_file="$ACTIVE_DIR/call-$ts-summary.json"
  cat > "$summary_json_file" <<JSON_EOF
{
  "transcript": "$ACTIVE_DIR/call-$ts-transcript.txt",
  "summary": "$ACTIVE_DIR/call-$ts-summary.txt",
  "facts": [],
  "prices": [],
  "times": [],
  "locations": [],
  "open_questions": []
}
JSON_EOF

  echo "Anruf abgeschlossen."
  echo "  Call-Datei:       $call_file"
  echo "  Transkript:       $transcript_file"
  echo "  Zusammenfassung:  $summary_file"
  echo "  Summary-JSON:     $summary_json_file"
}

cmd_summarize() {
  if [ ! -f "$LAST_CALL_FILE" ]; then
    echo "No last call data found. Run a mock or request first."
    return 0
  fi

  local ts
  ts="$(sed -n 's/.*"timestamp": "\([^"]*\)".*/\1/p' "$LAST_CALL_FILE" | head -1)"

  local summary_file="$ACTIVE_DIR/call-$ts-summary.txt"
  local summary_json_file="$ACTIVE_DIR/call-$ts-summary.json"

  if [ -f "$summary_file" ]; then
    echo "Call Summary for $ts"
    echo "===================="
    echo ""
    cat "$summary_file"
  else
    local number lang goal status
    number="$(sed -n 's/.*"number": "\([^"]*\)".*/\1/p' "$LAST_CALL_FILE" | head -1)"
    lang="$(sed -n 's/.*"language": "\([^"]*\)".*/\1/p' "$LAST_CALL_FILE" | head -1)"
    goal="$(sed -n 's/.*"goal": "\([^"]*\)".*/\1/p' "$LAST_CALL_FILE" | head -1)"
    status="$(sed -n 's/.*"status": "\([^"]*\)".*/\1/p' "$LAST_CALL_FILE" | head -1)"

    echo "Summary (from last-call.json metadata)"
    echo "======================================"
    echo "  Number:     $(mask_phone "$number")"
    echo "  Language:   $lang"
    echo "  Goal:       $goal"
    echo "  Status:     $status"
    echo ""
    echo "This call has no detailed summary file."
  fi

  if [ ! -f "$summary_json_file" ]; then
    local number lang goal
    number="$(sed -n 's/.*"number": "\([^"]*\)".*/\1/p' "$LAST_CALL_FILE" | head -1)"
    lang="$(sed -n 's/.*"language": "\([^"]*\)".*/\1/p' "$LAST_CALL_FILE" | head -1)"
    goal="$(sed -n 's/.*"goal": "\([^"]*\)".*/\1/p' "$LAST_CALL_FILE" | head -1)"

    cat > "$summary_json_file" <<JSON_EOF
{
  "transcript": "nicht vorhanden",
  "summary": "nicht vorhanden",
  "facts": [],
  "prices": [],
  "times": [],
  "locations": [],
  "open_questions": []
}
JSON_EOF
    echo ""
    echo "Summary-JSON erzeugt: $summary_json_file"
  fi
}

case "$COMMAND" in
  help|-h|--help)
    show_help
    ;;
  setup)
    cmd_setup
    ;;
  check)
    cmd_check
    ;;
  gemini-check)
    cmd_gemini_check
    ;;
  twilio-check)
    cmd_twilio_check
    ;;
  mock)
    cmd_mock "$@"
    ;;
  request)
    cmd_request "$@"
    ;;
  execute-pending)
    cmd_execute_pending
    ;;
  status)
    cmd_status
    ;;
  last)
    cmd_last
    ;;
  transcript)
    cmd_transcript
    ;;
  summarize)
    cmd_summarize
    ;;
  *)
    echo "Unknown command: $COMMAND"
    echo ""
    show_help
    exit 1
    ;;
esac
