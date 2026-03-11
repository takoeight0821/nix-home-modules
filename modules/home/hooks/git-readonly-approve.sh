#!/bin/bash
# git-readonly-approve.sh - Claude Code PreToolUse hook for Bash commands
#
# Auto-approves read-only git commands by analyzing the git subcommand.
# Parses global git options (-C, --git-dir, --work-tree, etc.) to correctly
# extract the subcommand, then checks against a whitelist of safe operations.
# Also handles piped/chained commands (||, &&, ;, |) by validating each segment.
#
# Safe subcommands: status, diff, log, show, branch, rev-parse, remote, tag,
#   shortlog, describe, rev-list, ls-files, ls-tree, ls-remote, cat-file,
#   name-rev, merge-base, count-objects, for-each-ref, blame, annotate, grep,
#   version, help, stash list, stash show
#
# Usage: Register as a PreToolUse hook with matcher "Bash" in Claude Code settings.
#   Input: JSON from stdin with .tool_input.command
#   Output: JSON with permissionDecision "allow" for safe git commands, or nothing
#
# Dependencies: jq, sed

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

STRIPPED=$(echo "$COMMAND" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

SAFE_SUBCMDS=" status diff log show branch rev-parse remote tag shortlog describe rev-list ls-files ls-tree ls-remote cat-file name-rev merge-base count-objects for-each-ref blame annotate grep version help "
SAFE_STASH=" list show "

extract_subcmd() {
  local -a w
  read -ra w <<< "$1"
  [[ "${w[0]:-}" == "git" ]] || return 1
  local i=1 n=${#w[@]}
  while (( i < n )); do
    case "${w[i]}" in
      -C|-c)                   (( i += 2 )) ;;
      --git-dir|--work-tree|--namespace|--exec-path)
                               (( i += 2 )) ;;
      --git-dir=*|--work-tree=*|--namespace=*|--exec-path=*|--config-env=*)
                               (( i += 1 )) ;;
      --no-pager|--paginate|-p|--bare|--no-replace-objects|--literal-pathspecs|--glob-pathspecs|--noglob-pathspecs|--icase-pathspecs|--no-optional-locks|--no-lazy-fetch|--no-advice)
                               (( i += 1 )) ;;
      -*)                      return 1 ;;
      *)
        local sub="${w[i]}"
        local next="${w[i+1]:-}"
        if [[ "$sub" == "stash" ]]; then
          echo "stash $next"
        else
          echo "$sub"
        fi
        return 0
        ;;
    esac
  done
  return 1
}

is_safe_git() {
  local sub
  sub=$(extract_subcmd "$1") || return 1
  if [[ "$sub" == stash\ * ]]; then
    local stash_sub="${sub#stash }"
    [[ "$SAFE_STASH" == *" $stash_sub "* ]] && return 0
    return 1
  fi
  [[ "$SAFE_SUBCMDS" == *" $sub "* ]]
}

NL=$'\n'
work="$STRIPPED"
work="${work//||/$NL}"
work="${work//&&/$NL}"
work="${work//;/$NL}"
work="${work//|/$NL}"

found_git=false

while IFS= read -r seg; do
  seg="${seg#"${seg%%[![:space:]]*}"}"
  seg="${seg%"${seg##*[![:space:]]}"}"
  [[ -z "$seg" ]] && continue

  if [[ "$seg" == git || "$seg" == git[[:space:]]* ]]; then
    found_git=true
    if ! is_safe_git "$seg"; then
      exit 0
    fi
  else
    exit 0
  fi
done <<< "$work"

if $found_git; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
      permissionDecisionReason: "Readonly git command auto-approved (global flags detected)."
    }
  }'
fi

exit 0
