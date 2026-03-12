#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ERRORS=""

if [[ "${1:-}" != "--script" ]]; then
  echo "Usage: bash test-gh-api-readonly.sh --script <path>" >&2
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

assert_denied_contains() {
  local cmd="$1"
  local desc="$2"
  local substring="$3"
  local output
  output=$(run_hook "$cmd")

  if ! echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL: $desc (expected deny, got: $output)"$'\n'
    echo "  FAIL: $desc"
    return
  fi

  local reason
  reason=$(echo "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason // ""')
  if echo "$reason" | grep -qF "$substring"; then
    PASS=$((PASS + 1))
    echo "  PASS: $desc"
  else
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL: $desc (expected reason to contain '$substring', got: $reason)"$'\n'
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

echo "=== Allowed: explicit GET ==="

assert_allowed 'gh api --method GET /repos/owner/repo' "gh api --method GET"
assert_allowed 'gh api -X GET /repos/owner/repo' "gh api -X GET"

echo ""
echo "=== Denied: no explicit GET ==="

assert_denied 'gh api /repos/owner/repo' "gh api without method"
assert_denied 'gh api /repos/owner/repo --paginate' "gh api with --paginate but no GET"
assert_denied 'gh api --method POST /repos/owner/repo' "gh api --method POST"
assert_denied 'gh api --method DELETE /repos/owner/repo' "gh api --method DELETE"

echo ""
echo "=== Allowed: non-gh-api commands ==="

assert_allowed 'gh pr list' "gh pr list (not gh api)"
assert_allowed 'ls -la' "ls (not gh)"

echo ""
echo "=== Denied: chained commands ==="

assert_denied 'echo foo && gh api /repos/owner/repo' "chained: echo && gh api without GET"

echo ""
echo "=== PR reply path guidance ==="

assert_denied_contains \
  'gh api /repos/owner/repo/pulls/42/comments/1/replies' \
  "PR reply path includes gh-pr-reply guidance" \
  "gh-pr-reply"

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
