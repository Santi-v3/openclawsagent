#!/usr/bin/env bash
set -euo pipefail

TASK="${*:-}"
MODEL="${SAGENT_OPENCODE_MODEL:-opencode/deepseek-v4-flash-free}"
WORKSPACE="$HOME/.openclaw/workspace"
OPENCODE_DIR="$WORKSPACE/opencode"
HISTORY_DIR="$OPENCODE_DIR/history"
OUTPUT_FILE="$OPENCODE_DIR/last-output.txt"
STATUS_FILE="$OPENCODE_DIR/last-status.json"
TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"
HISTORY_FILE="$HISTORY_DIR/opencode-$TIMESTAMP.txt"
CURRENT_DIR="$(pwd -P)"

if [ -z "$TASK" ]; then
  echo "Usage: scripts/sagent-opencode-worker.sh \"<coding task>\""
  exit 1
fi

mkdir -p "$OPENCODE_DIR" "$HISTORY_DIR"

json_escape() {
  local value="${1:-}"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

is_allowed_cwd() {
  case "$CURRENT_DIR" in
    "$HOME"|"$HOME/Desktop"|"$HOME/Desktop/"*|"$HOME/Downloads"|"$HOME/Downloads/"*|"$HOME/Documents"|"$HOME/Documents/"*|"$HOME/Library/Mobile Documents"|"$HOME/Library/Mobile Documents/"*|"$HOME/.ssh"|"$HOME/.ssh/"*)
      return 1
      ;;
    "$WORKSPACE"|"$WORKSPACE/"*|"$HOME/Projects"|"$HOME/Projects/"*)
      return 0
      ;;
    "$HOME/.openclaw"|"$HOME/.openclaw/"*)
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}

write_status() {
  local exit_code="$1"
  local escaped_cwd escaped_model escaped_task escaped_output escaped_history
  escaped_cwd="$(json_escape "$CURRENT_DIR")"
  escaped_model="$(json_escape "$MODEL")"
  escaped_task="$(json_escape "$TASK")"
  escaped_output="$(json_escape "$OUTPUT_FILE")"
  escaped_history="$(json_escape "$HISTORY_FILE")"

  cat > "$STATUS_FILE" <<STATUS_EOF
{
  "timestamp": "$TIMESTAMP",
  "cwd": "$escaped_cwd",
  "model": "$escaped_model",
  "task": "$escaped_task",
  "output_file": "$escaped_output",
  "history_file": "$escaped_history",
  "exit_code": $exit_code
}
STATUS_EOF
}

if ! is_allowed_cwd; then
  {
    echo "OpenCode worker refused to run from disallowed path: $CURRENT_DIR"
    echo "Allowed paths:"
    echo "  $HOME/Projects"
    echo "  $WORKSPACE"
  } | tee "$OUTPUT_FILE"
  cp "$OUTPUT_FILE" "$HISTORY_FILE"
  write_status 30
  exit 30
fi

if ! command -v opencode >/dev/null 2>&1; then
  {
    echo "opencode CLI not available."
  } | tee "$OUTPUT_FILE"
  cp "$OUTPUT_FILE" "$HISTORY_FILE"
  write_status 1
  exit 1
fi

EXTERNAL_READ_PATHS="${SAGENT_OPENCODE_READ_PATHS:-}"

SAFETY_PREFIX="Du bist der Sagent OpenCode Worker.

Schreibzugriff:
- Arbeite und ändere Dateien ausschließlich im aktuellen Projektordner.
- Keine Änderungen außerhalb des aktuellen Projektordners.

Lesezugriff:
- Du darfst Dateien im aktuellen Projektordner lesen.
- Zusätzlich darfst du ausschließlich die folgenden externen Pfade lesend verwenden:
${EXTERNAL_READ_PATHS:-keine}
- Außerhalb dieser Pfade darfst du nichts lesen.

Sicherheit:
- Lies keine Secrets.
- Keine .env-Dateien.
- Keine SSH-Keys.
- Keine Tokens oder API-Keys ausgeben.
- Kein git push.
- Kein Deploy.
- Keine externen oder kostenpflichtigen Aktionen.
- Wenn nicht ausdrücklich nach Änderungen gefragt wird, ändere keine Dateien.
- Fasse Ergebnis und Risiken kurz zusammen."
MESSAGE="$SAFETY_PREFIX

Task:
$TASK"

echo "Running OpenCode worker..."
echo "Model: $MODEL"
echo "Working directory: $CURRENT_DIR"

set +e
opencode run --model "$MODEL" "$MESSAGE" 2>&1 | tee "$OUTPUT_FILE"
OPENCODE_EXIT=${PIPESTATUS[0]}
set -e

cp "$OUTPUT_FILE" "$HISTORY_FILE"
write_status "$OPENCODE_EXIT"

echo ""
echo "Saved OpenCode output to: $OUTPUT_FILE"
echo "Saved OpenCode history to: $HISTORY_FILE"
echo "Saved OpenCode status to: $STATUS_FILE"

exit "$OPENCODE_EXIT"
