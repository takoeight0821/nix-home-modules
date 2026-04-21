#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ERRORS=""

if [[ "${1:-}" != "--script" ]]; then
  echo "Usage: bash test-prefer-rg.sh --script <path>" >&2
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

assert_denied() {
  local cmd="$1"
  local desc="$2"
  local output
  output=$(run_hook "$cmd")

  if echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
    PASS=$((PASS + 1))
    echo "  PASS: $desc"
  else
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL: $desc (expected deny, got: $output)"$'\n'
    echo "  FAIL: $desc"
  fi
}

assert_allowed() {
  local cmd="$1"
  local desc="$2"
  local output
  output=$(run_hook "$cmd")

  if [ -z "$output" ] || ! echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
    PASS=$((PASS + 1))
    echo "  PASS: $desc"
  else
    FAIL=$((FAIL + 1))
    local reason
    reason=$(echo "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason // "unknown"')
    ERRORS+="  FAIL: $desc (expected allow, got deny: $reason)"$'\n'
    echo "  FAIL: $desc"
  fi
}

echo "=== True Positives (should be blocked) ==="

assert_denied 'grep foo file.txt' "bare grep"
assert_denied 'grep -r pattern .' "grep -r"
assert_denied 'grep -E "foo|bar" file' "grep -E with quoted alt"
assert_denied 'cat file | grep foo' "piped grep"
assert_denied 'ls && grep foo file' "chained with &&"
assert_denied 'ls; grep foo file' "chained with ;"
assert_denied 'ls || grep foo file' "chained with ||"
assert_denied 'find . -type f | xargs grep foo' "xargs grep"

echo ""
echo "=== True Negatives (should be allowed) ==="

assert_allowed 'rg foo file.txt' "rg instead of grep"
assert_allowed 'git grep foo' "git grep (built-in)"
assert_allowed 'git  grep  foo' "git grep with extra spaces"
assert_allowed 'git -C /some/path grep foo' "git -C path grep"
assert_allowed 'git --no-pager grep foo' "git --no-pager grep"
assert_allowed 'git -c user.name=x grep foo' "git -c config grep"
assert_allowed 'git --git-dir=.git --work-tree=. grep foo' "git with dir flags grep"
assert_allowed 'pgrep -f daemon' "pgrep (process grep)"
assert_allowed 'egrep foo file' "egrep"
assert_allowed 'fgrep foo file' "fgrep"
assert_allowed 'ripgrep foo file' "ripgrep literal"
assert_allowed 'zgrep foo file.gz' "zgrep"
assert_allowed 'ls -la' "unrelated: ls"
assert_allowed 'echo "grep is a word"' "grep inside double quotes"
assert_allowed "echo 'use grep sparingly'" "grep inside single quotes"
assert_allowed 'cat README.md' "unrelated: cat"

echo ""
echo "=== Mixed scenarios ==="

assert_denied 'git status && grep foo file' "git status then grep"
assert_allowed 'git grep foo && git status' "git grep then status"

echo ""
echo "=========================================="
echo "Total: $((PASS + FAIL)) | Passed: $PASS | Failed: $FAIL"
echo "=========================================="

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Failures:"
  echo "$ERRORS"
  exit 1
fi

exit 0
