#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ERRORS=""

if [[ "${1:-}" != "--script" ]]; then
  echo "Usage: bash test-rewrite-git-c.sh --script <path>" >&2
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

assert_rewritten() {
  local cmd="$1"
  local expected="$2"
  local desc="$3"
  local output
  output=$(run_hook "$cmd")

  local actual
  actual=$(echo "$output" | jq -r '.updatedInput.command // empty')

  if [[ "$actual" == "$expected" ]]; then
    PASS=$((PASS + 1))
    echo "  PASS: $desc"
  else
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL: $desc (expected: '$expected', got: '$actual')"$'\n'
    echo "  FAIL: $desc"
  fi
}

assert_unchanged() {
  local cmd="$1"
  local desc="$2"
  local output
  output=$(run_hook "$cmd")

  if [ -z "$output" ] || ! echo "$output" | jq -e '.updatedInput.command' >/dev/null 2>&1; then
    PASS=$((PASS + 1))
    echo "  PASS: $desc"
  else
    local rewritten
    rewritten=$(echo "$output" | jq -r '.updatedInput.command')
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL: $desc (expected no rewrite, got: '$rewritten')"$'\n'
    echo "  FAIL: $desc"
  fi
}

echo "=== Basic rewriting ==="

assert_rewritten 'git -C /tmp/repo log' \
  'cd /tmp/repo && git log' \
  "simple: git -C /path log"

assert_rewritten 'git -C /tmp/repo log --oneline' \
  'cd /tmp/repo && git log --oneline' \
  "with subcommand flags: git -C /path log --oneline"

assert_rewritten 'git -C /tmp/repo status' \
  'cd /tmp/repo && git status' \
  "status: git -C /path status"

echo ""
echo "=== Quoted paths ==="

assert_rewritten 'git -C "/tmp/my repo" status' \
  'cd "/tmp/my repo" && git status' \
  "double-quoted path with spaces"

assert_rewritten "git -C '/tmp/my repo' status" \
  "cd '/tmp/my repo' && git status" \
  "single-quoted path with spaces"

echo ""
echo "=== Pipe and chained commands ==="

assert_rewritten 'git -C /tmp/repo log | head' \
  'cd /tmp/repo && git log | head' \
  "pipe: git -C /path log | head"

assert_rewritten 'git -C /tmp/repo log --oneline | wc -l' \
  'cd /tmp/repo && git log --oneline | wc -l' \
  "pipe with flags: git -C /path log --oneline | wc -l"

echo ""
echo "=== Should NOT rewrite ==="

assert_unchanged 'git log --oneline' \
  "no -C: git log"

assert_unchanged 'git status' \
  "no -C: git status"

assert_unchanged 'ls -la' \
  "unrelated command: ls"

assert_unchanged 'echo "git -C /tmp/repo log"' \
  "double-quoted: git -C in echo"

assert_unchanged "echo 'git -C /tmp/repo log'" \
  "single-quoted: git -C in echo"

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
