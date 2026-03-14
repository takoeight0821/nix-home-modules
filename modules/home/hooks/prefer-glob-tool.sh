#!/bin/bash
set -euo pipefail
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

STRIPPED=$(echo "$COMMAND" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

if ! echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)(find|fd)\b'; then
  exit 0
fi

jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "Use the Glob tool instead of find/fd in Bash. The Glob tool provides better output formatting and respects permission settings."
  }
}'
exit 0
