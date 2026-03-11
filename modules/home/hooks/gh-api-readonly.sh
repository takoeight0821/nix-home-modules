#!/bin/bash
# gh-api-readonly.sh - Claude Code PreToolUse hook for Bash commands
#
# Enforces read-only usage of `gh api` by requiring explicit `--method GET`.
# Without this, `gh api` defaults to GET but could be used with POST/PATCH/DELETE
# for write operations. This hook denies any `gh api` call that doesn't explicitly
# specify `--method GET` (or `-X GET`), and suggests using `gh-pr-reply` for
# PR review comment replies.
#
# Usage: Register as a PreToolUse hook with matcher "Bash" in Claude Code settings.
#   Input: JSON from stdin with .tool_input.command
#   Output: JSON with permissionDecision "deny" and reason, or nothing if safe
#
# Dependencies: jq, grep

set -euo pipefail
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

if ! echo "$COMMAND" | grep -qE '(^|\s|&&|\|\||;)gh\s+api\b'; then
  exit 0
fi

if echo "$COMMAND" | grep -qiE '(--method|-X)\s+GET\b'; then
  exit 0
fi

if echo "$COMMAND" | grep -qE '/pulls/[0-9]+/comments/[0-9]+/replies'; then
  REASON="gh api requires explicit --method GET. To reply to a PR review comment, use: gh-pr-reply <owner/repo> <pull_number> <comment_id> <body>"
else
  REASON="gh api requires explicit --method GET. Add --method GET to use gh api."
fi

jq -n --arg reason "$REASON" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'
