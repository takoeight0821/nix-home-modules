#!/bin/bash
# block-dangerous-flags.sh - Claude Code PreToolUse hook for Bash commands
#
# Blocks dangerous command flags that could cause unintended data loss or side effects.
# Denied patterns:
#   - sed -i / --in-place (in-place file editing)
#   - find with -delete/-exec/-execdir/-ok/-okdir/-fls/-fprint (side effects)
#   - fd with --exec/--exec-batch (side effects)
#   - sort -o / --output (overwrite file)
#   - nix store delete/gc/repair/optimise (destructive store operations)
#   - nix profile remove/wipe-history (destructive profile operations)
#   - nix-env --uninstall/--delete-generations (destructive env operations)
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

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)sed\b' && \
   echo "$STRIPPED" | grep -qE '[[:space:]]-[^[:space:]]*i|[[:space:]]--in-place\b'; then
  deny "sed -i (in-place edit) is not allowed. Use sed without -i to output to stdout."
fi

if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)find\b' && \
   echo "$STRIPPED" | grep -qE '\s-(delete|exec|execdir|ok|okdir|fls|fprint0?|fprintf)\b'; then
  deny "find with -delete/-exec/-execdir/-ok/-okdir/-fls/-fprint is not allowed. Use find for listing only."
fi

if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)fd\b' && \
   echo "$STRIPPED" | grep -qE '\s(-x|--exec|-X|--exec-batch)\b'; then
  deny "fd with --exec/--exec-batch is not allowed. Use fd for listing only."
fi

if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)sort\b' && \
   echo "$STRIPPED" | grep -qE '\s(-o|--output)\b'; then
  deny "sort -o (output to file) is not allowed. Use sort to output to stdout."
fi

if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)nix\b' && \
   echo "$STRIPPED" | grep -qE '\bstore\s+(delete|gc|repair|optimise)\b'; then
  deny "nix store delete/gc/repair/optimise is not allowed via auto-approve. Run manually if needed."
fi

if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)nix\b' && \
   echo "$STRIPPED" | grep -qE '\bprofile\s+(remove|wipe-history)\b'; then
  deny "nix profile remove/wipe-history is not allowed via auto-approve. Run manually if needed."
fi

if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)nix-env\b' && \
   echo "$STRIPPED" | grep -qE '\s--(uninstall|delete-generations)\b|\s-e\b'; then
  deny "nix-env --uninstall/--delete-generations is not allowed via auto-approve. Run manually if needed."
fi

exit 0
