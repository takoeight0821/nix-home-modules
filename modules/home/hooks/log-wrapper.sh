#!/usr/bin/env bash
set -euo pipefail

HOOK_NAME="${1:?usage: log-wrapper.sh <hook-name> <script>}"
SCRIPT="${2:?usage: log-wrapper.sh <hook-name> <script>}"
LOG_FILE="$HOME/.claude/hooks.log"

if [[ -f "$LOG_FILE" ]] && (( $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) > 1048576 )); then
  mv -f "$LOG_FILE" "${LOG_FILE}.old"
fi

stdin_data=$(cat)

set +e
stdout_data=$(printf '%s' "$stdin_data" | bash "$SCRIPT" 2>/dev/null)
exit_code=$?
set -e

cmd=""
if [[ -n "$stdin_data" ]]; then
  cmd=$(printf '%s' "$stdin_data" | jq -r '.tool_input.command // .tool_input.input // "" ' 2>/dev/null || true)
fi
cmd="${cmd:0:80}"

result="passthrough"
if [[ -n "$stdout_data" ]]; then
  if printf '%s' "$stdout_data" | jq -e '.permissionDecision' >/dev/null 2>&1; then
    result=$(printf '%s' "$stdout_data" | jq -r '.permissionDecision')
  elif printf '%s' "$stdout_data" | jq -e '.updatedInput // .tool_input' >/dev/null 2>&1; then
    result="rewrite"
  elif printf '%s' "$stdout_data" | jq -e '.systemMessage' >/dev/null 2>&1; then
    result="message"
  fi
fi

timestamp=$(date +%H:%M:%S)
printf '%s [%s] %s cmd="%s"\n' "$timestamp" "$HOOK_NAME" "$result" "$cmd" >> "$LOG_FILE"

if [[ -n "$stdout_data" ]]; then
  printf '%s' "$stdout_data"
fi

exit "$exit_code"
