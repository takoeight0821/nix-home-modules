#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ERRORS=""

if [[ "${1:-}" != "--script" ]]; then
  echo "Usage: bash test-block-package-install.sh --script <path>" >&2
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

# npm
assert_denied 'npm install lodash' "npm install with package"
assert_denied 'npm install' "npm install bare"
assert_denied 'npm i express' "npm i shorthand"
assert_denied 'npm add typescript' "npm add"
assert_denied 'cd myapp && npm install react' "npm install in subshell"

# pnpm
assert_denied 'pnpm install' "pnpm install bare"
assert_denied 'pnpm install zod' "pnpm install with package"
assert_denied 'pnpm add vite' "pnpm add"
assert_denied 'pnpm i axios' "pnpm i shorthand"

# yarn
assert_denied 'yarn install' "yarn install bare"
assert_denied 'yarn add lodash' "yarn add"

# pip
assert_denied 'pip install requests' "pip install"
assert_denied 'pip3 install numpy' "pip3 install"
assert_denied 'pip install -r requirements.txt' "pip install -r"

# brew
assert_denied 'brew install wget' "brew install"
assert_denied 'brew reinstall curl' "brew reinstall"

# cargo
assert_denied 'cargo install ripgrep' "cargo install"

# gem
assert_denied 'gem install rails' "gem install"

# nix-env
assert_denied 'nix-env --install nixpkgs.hello' "nix-env --install"
assert_denied 'nix-env -i hello' "nix-env -i"

# nix profile install
assert_denied 'nix profile install nixpkgs#hello' "nix profile install"

echo ""
echo "=== True Negatives (should be allowed) ==="

# npm non-install commands
assert_allowed 'npm run build' "npm run"
assert_allowed 'npm test' "npm test"
assert_allowed 'npm ls' "npm ls"
assert_allowed 'npm audit' "npm audit"
assert_allowed 'npm ci' "npm ci"

# pnpm non-install commands
assert_allowed 'pnpm run dev' "pnpm run"
assert_allowed 'pnpm test' "pnpm test"
assert_allowed 'pnpm dlx tsc --noEmit' "pnpm dlx"

# yarn non-install commands
assert_allowed 'yarn run build' "yarn run"
assert_allowed 'yarn test' "yarn test"

# pip non-install commands
assert_allowed 'pip show requests' "pip show"
assert_allowed 'pip list' "pip list"
assert_allowed 'pip freeze' "pip freeze"

# brew non-install commands
assert_allowed 'brew list' "brew list"
assert_allowed 'brew info wget' "brew info"
assert_allowed 'brew search wget' "brew search"
assert_allowed 'brew upgrade' "brew upgrade"

# cargo non-install commands
assert_allowed 'cargo build' "cargo build"
assert_allowed 'cargo test' "cargo test"
assert_allowed 'cargo run' "cargo run"

# gem non-install commands
assert_allowed 'gem list' "gem list"

# nix-env non-install commands
assert_allowed 'nix-env --query' "nix-env --query"
assert_allowed 'nix-env -q' "nix-env -q"

# nix profile non-install commands
assert_allowed 'nix profile list' "nix profile list"
assert_allowed 'nix profile history' "nix profile history"
assert_allowed 'nix profile diff-closures' "nix profile diff-closures"

echo ""
echo "=== Quoted String Bypass Resistance ==="

assert_denied "npm install 'lodash'" "npm install with quoted package"
assert_denied 'npm install "express"' "npm install with double-quoted package"
assert_denied "pip install 'numpy==1.0'" "pip install with quoted version"

echo ""
echo "=== Results ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Failures:"
  echo "$ERRORS"
  exit 1
fi
