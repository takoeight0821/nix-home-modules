#!/bin/bash
# gh-pr-reply - Helper script for replying to GitHub PR review comments
#
# Wraps `gh api --method POST` to create replies to PR review comments.
# Used alongside gh-api-readonly.sh hook, which blocks direct `gh api` POST calls
# and suggests using this script instead.
#
# Usage: gh-pr-reply <owner/repo> <pull_number> <comment_id> <body>
#   Example: gh-pr-reply octocat/hello-world 42 123456 "Thanks for the review!"
#
# Install: Place in PATH (e.g., ~/.local/bin/gh-pr-reply) and make executable.
#
# Dependencies: gh (GitHub CLI)

set -euo pipefail
if [[ $# -ne 4 ]]; then
  echo "Usage: gh-pr-reply <owner/repo> <pull_number> <comment_id> <body>" >&2
  exit 1
fi
gh api --method POST \
  -H "Accept: application/vnd.github+json" \
  "/repos/$1/pulls/$2/comments/$3/replies" \
  -f body="$4"
