#!/bin/bash
# post-git-push-watch.sh - Claude Code PostToolUse hook for Bash commands
#
# After a `git push` or `gh pr create` command, waits briefly then watches
# CI checks using `gh pr checks --watch --fail-fast`. Reports check results
# (pass or fail) back as a systemMessage so Claude Code is aware of CI status.
#
# Usage: Register as a PostToolUse hook with matcher "Bash" in Claude Code settings.
#   Input: JSON from stdin with .tool_input.command
#   Output: JSON systemMessage with CI check results, or nothing if not a push
#
# Dependencies: jq, sed, grep, gh (GitHub CLI)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

STRIPPED=$(echo "$COMMAND" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

if ! echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)(git\s+push|gh\s+pr\s+create)\b'; then
  exit 0
fi

if ! gh pr view --json number >/dev/null 2>&1; then
  exit 0
fi

CHECKS_OUTPUT=$(gh pr checks --watch --fail-fast 2>&1) || {
  jq -n --arg out "$CHECKS_OUTPUT" '{
    systemMessage: ("gh pr checks failed: " + $out)
  }'
  exit 0
}

jq -n --arg out "$CHECKS_OUTPUT" '{
  systemMessage: ("CI checks passed:\n" + $out)
}'
exit 0
