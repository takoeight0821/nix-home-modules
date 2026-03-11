#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ERRORS=""

if [[ "${1:-}" != "--script" ]]; then
  echo "Usage: bash test-block-dangerous-flags.sh --script <path>" >&2
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

assert_denied 'sed -i s/foo/bar/ file.txt' "sed -i (short flag)"
assert_denied 'sed --in-place s/foo/bar/ file.txt' "sed --in-place (long flag)"
assert_denied 'find . -delete' "find -delete"
assert_denied 'find . -exec rm {} \;' "find -exec"
assert_denied 'find . -execdir cmd {} \;' "find -execdir"
assert_denied 'fd pattern -x cmd' "fd -x (short exec)"
assert_denied 'fd pattern --exec cmd' "fd --exec (long flag)"
assert_denied 'fd pattern -X cmd' "fd -X (short exec-batch)"
assert_denied 'fd pattern --exec-batch cmd' "fd --exec-batch (long flag)"
assert_denied 'sort -o output.txt input.txt' "sort -o (short flag)"
assert_denied 'sort --output output.txt input.txt' "sort --output (long flag)"
assert_denied 'echo foo && find . -delete' "chained: echo && find -delete"

echo ""
echo "=== True Negatives (should be allowed) ==="

assert_allowed 'sed s/foo/bar/ file.txt' "sed without -i"
assert_allowed 'find . -name "*.txt"' "find with safe flags"
assert_allowed 'fd pattern' "fd without exec"
assert_allowed 'sort input.txt' "sort without -o"
assert_allowed 'ls -la' "unrelated command: ls"

echo ""
echo "=== False Positive Prevention (quoted strings) ==="

assert_allowed 'git commit -m "fixed find -delete issue"' "double-quoted: find -delete in commit message"
assert_allowed 'echo "use sed -i for in-place"' "double-quoted: sed -i in echo"
assert_allowed "git commit -m 'sort -o is dangerous'" "single-quoted: sort -o in commit message"
assert_allowed "echo 'fd --exec example'" "single-quoted: fd --exec in echo"

echo ""
echo "=== Nix Destructive Commands (should be blocked) ==="

assert_denied 'nix store delete /nix/store/xxx' "nix store delete"
assert_denied 'nix store gc' "nix store gc"
assert_denied 'nix store repair /nix/store/xxx' "nix store repair"
assert_denied 'nix store optimise' "nix store optimise"
assert_denied 'nix profile remove 0' "nix profile remove"
assert_denied 'nix profile wipe-history' "nix profile wipe-history"
assert_denied 'nix-env --uninstall hello' "nix-env --uninstall"
assert_denied 'nix-env -e hello' "nix-env -e (short uninstall)"
assert_denied 'nix-env --delete-generations old' "nix-env --delete-generations"
assert_denied 'echo done && nix store gc' "chained: echo && nix store gc"

echo ""
echo "=== Nix Safe Commands (should be allowed) ==="

assert_allowed 'nix build .#primary' "nix build"
assert_allowed 'nix flake show' "nix flake show"
assert_allowed 'nix eval .#foo' "nix eval"
assert_allowed 'nix store ls /nix/store/xxx' "nix store ls (read-only)"
assert_allowed 'nix store path-info /nix/store/xxx' "nix store path-info (read-only)"
assert_allowed 'nix profile list' "nix profile list (read-only)"
assert_allowed 'nix profile history' "nix profile history (read-only)"
assert_allowed 'nix-env --query --installed' "nix-env --query (read-only)"
assert_allowed 'nix-env -q' "nix-env -q (read-only)"

echo ""
echo "=== Nix False Positive Prevention (quoted strings) ==="

assert_allowed 'echo "nix store gc clears the store"' "double-quoted: nix store gc in echo"
assert_allowed "git commit -m 'run nix store delete to clean up'" "single-quoted: nix store delete in commit message"
assert_allowed 'echo "use nix-env --uninstall to remove"' "double-quoted: nix-env --uninstall in echo"

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
