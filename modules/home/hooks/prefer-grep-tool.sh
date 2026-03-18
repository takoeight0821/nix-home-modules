#!/bin/bash
set -euo pipefail
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

STRIPPED=$(echo "$COMMAND" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

if ! echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)(grep|rg)\b'; then
  exit 0
fi

jq -n '{
  systemMessage: "Hint: Use the Grep tool instead of grep/rg in Bash. The Grep tool provides better output formatting and respects permission settings."
}'
exit 0
