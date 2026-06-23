#!/bin/bash
# block-force-push.sh - Claude Code PreToolUse hook for Bash commands
#
# Blocks all force-style git push operations, which can rewrite/destroy remote
# history. Denied flags (on a `git push` command):
#   --force / -f (including bundled short flags like -fu)
#   --force-with-lease (with or without =<value>)
#   --force-if-includes
#
# Only triggers when the command segment is actually `git push`; force flags
# inside other git subcommands, quoted strings, or unrelated commands pass through.
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

# Is this shell segment a `git push`? Skips git global options (-C, --git-dir, ...)
# to find the real subcommand.
is_git_push() {
  local -a w
  read -ra w <<< "$1"
  [[ "${w[0]:-}" == "git" ]] || return 1
  local i=1 n=${#w[@]}
  while ((i < n)); do
    case "${w[i]}" in
      -C | -c | --git-dir | --work-tree | --namespace | --exec-path)
        ((i += 2)) ;;
      --git-dir=* | --work-tree=* | --namespace=* | --exec-path=* | --config-env=*)
        ((i += 1)) ;;
      -*)
        ((i += 1)) ;;
      *)
        [[ "${w[i]}" == "push" ]]
        return
        ;;
    esac
  done
  return 1
}

has_force_flag() {
  echo " $1 " | grep -qE '[[:space:]](--force|--force-with-lease(=[^[:space:]]*)?|--force-if-includes|-[a-zA-Z]*f[a-zA-Z]*)[[:space:]]'
}

NL=$'\n'
work="$STRIPPED"
work="${work//||/$NL}"
work="${work//&&/$NL}"
work="${work//;/$NL}"
work="${work//|/$NL}"

while IFS= read -r seg; do
  seg="${seg#"${seg%%[![:space:]]*}"}"
  seg="${seg%"${seg##*[![:space:]]}"}"
  [[ -z "$seg" ]] && continue
  if is_git_push "$seg" && has_force_flag "$seg"; then
    deny "git push --force/-f/--force-with-lease/--force-if-includes is not allowed. Force push can destroy remote history. Run manually if you are certain."
  fi
done <<< "$work"

exit 0
