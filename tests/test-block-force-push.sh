#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ERRORS=""

if [[ "${1:-}" != "--script" ]]; then
  echo "Usage: bash test-block-force-push.sh --script <path>" >&2
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

echo "=== Force push variants (should be blocked) ==="

assert_denied 'git push --force' "git push --force"
assert_denied 'git push -f' "git push -f"
assert_denied 'git push --force origin main' "git push --force with args"
assert_denied 'git push -f origin main' "git push -f with args"
assert_denied 'git push --force-with-lease' "git push --force-with-lease"
assert_denied 'git push --force-with-lease=origin/main' "git push --force-with-lease=ref"
assert_denied 'git push --force-if-includes' "git push --force-if-includes"
assert_denied 'git push -fu origin main' "git push -fu (bundled short flags)"
assert_denied 'git push -uf origin main' "git push -uf (bundled short flags)"
assert_denied 'git -C repo push --force' "git -C dir push --force"
assert_denied 'echo ok && git push --force' "chained: echo && git push --force"
assert_denied 'git push origin main && git push --force' "chained: safe push && force push"

echo ""
echo "=== Safe pushes (should be allowed) ==="

assert_allowed 'git push' "git push (no flags)"
assert_allowed 'git push origin main' "git push origin main"
assert_allowed 'git push -u origin main' "git push -u (set-upstream)"
assert_allowed 'git push --set-upstream origin main' "git push --set-upstream"
assert_allowed 'git push --no-verify' "git push --no-verify"
assert_allowed 'git push --tags' "git push --tags"
assert_allowed 'git push --dry-run' "git push --dry-run"

echo ""
echo "=== Non-push / unrelated (should be allowed) ==="

assert_allowed 'git status' "git status"
assert_allowed 'git config -f .git/config user.name x' "git config -f (not push)"
assert_allowed 'git log --format=%f' "git log --format=%f (not push)"
assert_allowed 'ls -la' "unrelated command: ls"

echo ""
echo "=== False positive prevention (quoted strings) ==="

assert_allowed 'git commit -m "revert force push"' "double-quoted: force push in commit message"
assert_allowed "git commit -m 'use git push --force carefully'" "single-quoted: --force in commit message"
assert_allowed 'echo "git push --force is dangerous"' "double-quoted: --force in echo"

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
