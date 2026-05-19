#!/bin/bash
# block-package-install.sh - Claude Code PreToolUse hook for Bash commands
#
# Blocks package manager install commands to prevent Claude from imperatively
# installing packages outside of Nix management.
# Denied patterns:
#   - npm install / npm i / npm add
#   - pnpm install / pnpm add / pnpm i
#   - yarn install / yarn add
#   - pip install / pip3 install
#   - brew install / brew reinstall
#   - cargo install
#   - gem install
#   - nix-env --install / nix-env -i
#   - nix profile install
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

if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)npm\s+(install|i|add)\b'; then
  deny "npm install/add is not allowed. Manage packages through Nix (home-manager) instead."
fi

if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)pnpm\s+(install|add|i)\b'; then
  deny "pnpm install/add is not allowed. Manage packages through Nix (home-manager) instead."
fi

if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)yarn\s+(install|add)\b'; then
  deny "yarn install/add is not allowed. Manage packages through Nix (home-manager) instead."
fi

if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)pip3?\s+install\b'; then
  deny "pip install is not allowed. Manage Python packages through Nix (home-manager) instead."
fi

if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)brew\s+(install|reinstall)\b'; then
  deny "brew install is not allowed. Manage Homebrew packages through nix-darwin homebrew module instead."
fi

if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)cargo\s+install\b'; then
  deny "cargo install is not allowed. Manage Rust tools through Nix (home-manager) instead."
fi

if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)gem\s+install\b'; then
  deny "gem install is not allowed. Manage Ruby gems through Nix (home-manager) instead."
fi

if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)nix-env\b' && \
   echo "$STRIPPED" | grep -qE '\s(--install|-i)\b'; then
  deny "nix-env --install is not allowed. Use home-manager or flake-based Nix management instead."
fi

if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)nix\b' && \
   echo "$STRIPPED" | grep -qE '\bprofile\s+install\b'; then
  deny "nix profile install is not allowed. Use home-manager or flake-based Nix management instead."
fi

exit 0
