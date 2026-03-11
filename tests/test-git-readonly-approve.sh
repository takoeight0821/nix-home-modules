#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ERRORS=""

if [[ "${1:-}" != "--script" ]]; then
  echo "Usage: bash test-git-readonly-approve.sh --script <path>" >&2
  exit 1
fi
HOOK_SCRIPT="${2:?--script requires a path argument}"
chmod +x "$HOOK_SCRIPT"
echo "Hook script: $HOOK_SCRIPT"
echo ""

run_hook() {
  local cmd="$1"
  local input
  input=$(jq -n --arg cmd "$cmd" '{ tool_input: { command: $cmd } }')
  echo "$input" | bash "$HOOK_SCRIPT" 2>/dev/null
}

assert_approved() {
  local cmd="$1"
  local desc="$2"
  local output
  output=$(run_hook "$cmd")

  if echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "allow"' >/dev/null 2>&1; then
    PASS=$((PASS + 1))
    echo "  PASS: $desc"
  else
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL: $desc (expected allow, got: ${output:-<empty>})"$'\n'
    echo "  FAIL: $desc"
  fi
}

assert_fallthrough() {
  local cmd="$1"
  local desc="$2"
  local output
  output=$(run_hook "$cmd")

  if [ -z "$output" ] || ! echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "allow"' >/dev/null 2>&1; then
    PASS=$((PASS + 1))
    echo "  PASS: $desc"
  else
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL: $desc (expected fallthrough, got allow)"$'\n'
    echo "  FAIL: $desc"
  fi
}

echo "=== Approved: Readonly git with global flags ==="

assert_approved 'git -C /tmp/repo log' "git -C <dir> log"
assert_approved 'git -C /tmp/repo log --oneline' "git -C <dir> log --oneline"
assert_approved 'git --no-pager diff' "git --no-pager diff"
assert_approved 'git --no-pager log --oneline -5' "git --no-pager log with args"
assert_approved "git -c core.pager='' log" "git -c key=val log"
assert_approved 'git -c core.pager=cat -C /tmp/repo diff' "git -c + -C combined"
assert_approved 'git --git-dir=/tmp/repo/.git log' "git --git-dir=<path> log"
assert_approved 'git --git-dir /tmp/repo/.git log' "git --git-dir <path> (space) log"
assert_approved 'git --work-tree=/tmp/repo status' "git --work-tree=<path> status"
assert_approved 'git -C /tmp/repo rev-parse --git-dir' "git -C <dir> rev-parse"
assert_approved 'git -C /tmp/repo branch --show-current' "git -C <dir> branch"
assert_approved 'git -C /tmp/repo remote -v' "git -C <dir> remote"
assert_approved 'git -C /tmp/repo tag -l' "git -C <dir> tag"
assert_approved 'git -C /tmp/repo show HEAD' "git -C <dir> show"
assert_approved 'git -C /tmp/repo ls-files' "git -C <dir> ls-files"
assert_approved 'git -C /tmp/repo blame README.md' "git -C <dir> blame"
assert_approved 'git -C /tmp/repo for-each-ref' "git -C <dir> for-each-ref"

echo ""
echo "=== Approved: Safe stash subcommands ==="

assert_approved 'git -C /tmp/repo stash list' "git -C <dir> stash list"
assert_approved 'git --no-pager stash show' "git --no-pager stash show"

echo ""
echo "=== Approved: Plain readonly git (no global flags) ==="

assert_approved 'git log --oneline' "git log (no global flags)"
assert_approved 'git status' "git status (no global flags)"
assert_approved 'git diff HEAD' "git diff (no global flags)"

echo ""
echo "=== Fallthrough: Write operations with global flags ==="

assert_fallthrough 'git -C /tmp/repo push' "git -C <dir> push"
assert_fallthrough 'git -C /tmp/repo push origin main' "git -C <dir> push origin main"
assert_fallthrough 'git -C /tmp/repo commit -m "msg"' "git -C <dir> commit"
assert_fallthrough 'git -C /tmp/repo reset --hard' "git -C <dir> reset --hard"
assert_fallthrough 'git -C /tmp/repo checkout -- file.txt' "git -C <dir> checkout"
assert_fallthrough 'git -C /tmp/repo rebase main' "git -C <dir> rebase"
assert_fallthrough 'git -C /tmp/repo merge feature' "git -C <dir> merge"
assert_fallthrough 'git --no-pager push' "git --no-pager push"
assert_fallthrough 'git -C /tmp/repo add .' "git -C <dir> add"
assert_fallthrough 'git -C /tmp/repo clean -fd' "git -C <dir> clean"

echo ""
echo "=== Fallthrough: Unsafe stash subcommands ==="

assert_fallthrough 'git -C /tmp/repo stash pop' "git -C <dir> stash pop"
assert_fallthrough 'git -C /tmp/repo stash drop' "git -C <dir> stash drop"
assert_fallthrough 'git -C /tmp/repo stash push' "git -C <dir> stash push"
assert_fallthrough 'git -C /tmp/repo stash clear' "git -C <dir> stash clear"
assert_fallthrough 'git --no-pager stash apply' "git --no-pager stash apply"

echo ""
echo "=== Chain commands ==="

assert_fallthrough 'git -C /tmp/repo log && git -C /tmp/repo push' "chain: safe && unsafe git"
assert_fallthrough 'git -C /tmp/repo push && git -C /tmp/repo log' "chain: unsafe && safe git"
assert_fallthrough 'git -C /tmp/repo log || git -C /tmp/repo reset --hard' "chain: safe || unsafe git"
assert_fallthrough 'git -C /tmp/repo log; git -C /tmp/repo commit -m msg' "chain: safe ; unsafe git"
assert_approved 'git -C /tmp/repo log && git -C /tmp/repo diff' "chain: safe && safe git"
assert_approved 'git -C /tmp/repo status && git --no-pager log' "chain: both safe with different global flags"

echo ""
echo "=== Fallthrough: Non-git commands in chain ==="

assert_fallthrough 'git -C /tmp/repo log && echo done' "chain: git + non-git (echo)"
assert_fallthrough 'echo start && git -C /tmp/repo log' "chain: non-git + git"
assert_fallthrough 'ls -la && git -C /tmp/repo log' "chain: ls + git"

echo ""
echo "=== False Positive Prevention (quoted strings) ==="

assert_fallthrough 'echo "git -C /tmp/repo push"' "double-quoted: git push in echo"
assert_fallthrough "echo 'git -C /tmp/repo push'" "single-quoted: git push in echo"
assert_fallthrough 'git commit -m "fixed git -C /path issue"' "git commit with git in message (stripped)"

echo ""
echo "=== Edge cases ==="

assert_fallthrough 'git' "bare git (no subcommand)"
assert_fallthrough 'git -C /tmp/repo' "git with flags but no subcommand"
assert_fallthrough 'not-git log' "command that isn't git"
assert_fallthrough '' "empty command"
assert_fallthrough 'git -C /tmp/repo --unknown-flag log' "unknown global flag (safety: don't approve)"

echo ""

TOTAL=$((PASS + FAIL))
echo "=== Summary ==="
echo "  Total: $TOTAL  Passed: $PASS  Failed: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "=== Failures ==="
  echo "$ERRORS"
  exit 1
fi

echo ""
echo "All tests passed."
