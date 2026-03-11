#!/bin/bash
# prefer-jq.sh - Claude Code PreToolUse hook for Bash commands
#
# Detects `python -m json.tool` usage and automatically rewrites it to use `jq .` instead.
# This is an updatedInput hook: it modifies the command rather than blocking it.
#
# Usage: Register as a PreToolUse hook with matcher "Bash" in Claude Code settings.
#   Input: JSON from stdin with .tool_input.command
#   Output: JSON with updatedInput.command (rewritten) or nothing if no match
#
# Dependencies: jq, sed, grep

set -euo pipefail
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

STRIPPED=$(echo "$COMMAND" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

if ! echo "$STRIPPED" | grep -qE 'python3?[[:space:]]+-m[[:space:]]+json\.tool'; then
  exit 0
fi

NEW_COMMAND=$(echo "$COMMAND" | sed -E 's/python3?[[:space:]]+-m[[:space:]]+json\.tool/jq ./g')

jq -n --arg cmd "$NEW_COMMAND" '{
  updatedInput: {
    command: $cmd
  }
}'
exit 0
