#!/bin/bash
# prefer-rg.sh - Claude Code PreToolUse hook for Bash commands
#
# Denies `grep` invocations to encourage using `rg` (ripgrep) or the Grep tool.
# `git grep`, `pgrep`, `egrep`, `fgrep`, and `ripgrep` are not affected.
#
# Flags `grep` only when it appears at a command-execution position:
#   - at the start of the command (after optional whitespace)
#   - right after a shell operator: |, ||, &, &&, ;
#   - as the command passed to `xargs`
# Does not flag `grep` that appears inside argument text (paths, hyphenated
# identifiers, comments, or heredoc bodies), which used to cause false positives.
#
# Usage: Register as a PreToolUse hook with matcher "Bash" in Claude Code settings.
#   Input: JSON from stdin with .tool_input.command
#   Output: JSON with permissionDecision "deny" and reason, or nothing if safe
#
# Dependencies: jq, sed, grep

set -euo pipefail
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

# Strip quoted string literals so `grep` inside them is ignored.
STRIPPED=$(echo "$COMMAND" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

# Strip shell line comments (# ... end of line).
STRIPPED=$(echo "$STRIPPED" | sed 's/#.*$//')

# Detect `grep` only at command-execution positions:
#   - start of line (after optional whitespace)
#   - after one of: | || & && ;
#   - as the command run by `xargs` (possibly with flags in between)
# Note: `git grep` is not matched because `grep` is preceded by whitespace
# (not by ^ or one of |;&), so no special handling is required.
if echo "$STRIPPED" | grep -qE '(^|[|;&])[[:space:]]*grep\b|\bxargs\b[^|&;]*\bgrep\b'; then
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
