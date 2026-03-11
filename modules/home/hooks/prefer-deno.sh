#!/bin/bash
# prefer-deno.sh - Claude Code PreToolUse hook for Bash commands
#
# Detects Python usage in bash commands and suggests Deno as a safer alternative.
# Deno's built-in permission model makes it more suitable for auto-approval workflows.
#
# Usage: Register as a PreToolUse hook with matcher "Bash" in Claude Code settings.
#   Input: JSON from stdin with .tool_input.command
#   Output: JSON systemMessage suggesting Deno (or nothing if no Python detected)
#
# Dependencies: jq, sed, grep

set -euo pipefail
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

STRIPPED=$(echo "$COMMAND" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

if ! echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)python3?\b'; then
  exit 0
fi

jq -n '{
  systemMessage: "Consider using deno instead of python. Deno has a built-in permission model, making it safer for auto-approval."
}'
exit 0
