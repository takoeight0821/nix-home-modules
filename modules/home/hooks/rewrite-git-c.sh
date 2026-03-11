#!/bin/bash
# rewrite-git-c.sh - Claude Code PreToolUse hook for Bash commands
#
# Rewrites `git -C <path> <cmd>` to `cd <path> && git <cmd>` for better
# compatibility and readability. This is an updatedInput hook that modifies
# the command rather than blocking it. Handles quoted and unquoted paths.
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

if ! echo "$STRIPPED" | grep -qE '(^|\s)git\s.*-C\b'; then
  exit 0
fi

NEW_COMMAND=$(echo "$COMMAND" | sed -E \
  -e "s/git[[:space:]]+-C[[:space:]]+('[^']*')[[:space:]]*/cd \1 \&\& git /g" \
  -e 's/git[[:space:]]+-C[[:space:]]+("[^"]*")[[:space:]]*/cd \1 \&\& git /g' \
  -e 's/git[[:space:]]+-C[[:space:]]+([^[:space:]|&;]+)[[:space:]]*/cd \1 \&\& git /g')

if [[ "$NEW_COMMAND" == "$COMMAND" ]]; then
  exit 0
fi

jq -n --arg cmd "$NEW_COMMAND" '{
  updatedInput: {
    command: $cmd
  }
}'
exit 0
