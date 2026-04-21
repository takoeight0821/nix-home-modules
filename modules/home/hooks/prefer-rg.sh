#!/bin/bash
# prefer-rg.sh - Claude Code PreToolUse hook for Bash commands
#
# Denies `grep` invocations to encourage using `rg` (ripgrep) or the Grep tool.
# `git grep`, `pgrep`, `egrep`, `fgrep`, and `ripgrep` are not affected.
#
# Usage: Register as a PreToolUse hook with matcher "Bash" in Claude Code settings.
#   Input: JSON from stdin with .tool_input.command
#   Output: JSON with permissionDecision "deny" and reason, or nothing if safe
#
# Dependencies: jq, sed, grep

set -euo pipefail
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

STRIPPED=$(echo "$COMMAND" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

FILTERED=$(echo "$STRIPPED" | sed -E 's/\bgit[[:space:]]+grep\b//g')

if echo "$FILTERED" | grep -qE '\bgrep\b'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Use `rg` (ripgrep) or the Grep tool instead of `grep`. `rg` is faster and respects .gitignore. Allowed variants: `git grep`, `pgrep`, `egrep`, `fgrep`, `ripgrep`."
    }
  }'
  exit 0
fi

exit 0
