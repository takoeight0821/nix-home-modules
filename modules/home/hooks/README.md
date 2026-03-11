# Claude Code Hooks

Safety hooks for [Claude Code](https://claude.com/claude-code) that run on `PreToolUse`, `PostToolUse`, and other events. They block dangerous commands, auto-approve safe ones, and rewrite commands for compatibility.

All hooks are Bash scripts that receive JSON via stdin and output JSON to stdout.

## Hook Overview

| Script | Event | Type | Description |
|---|---|---|---|
| `block-dangerous-flags.sh` | PreToolUse | deny | Blocks destructive flags (`sed -i`, `find -delete`, `nix store gc`, etc.) |
| `git-readonly-approve.sh` | PreToolUse | allow | Auto-approves read-only git commands (`status`, `diff`, `log`, etc.) |
| `prefer-deno.sh` | PreToolUse | suggest | Suggests Deno when Python is used |
| `prefer-jq.sh` | PreToolUse | rewrite | Rewrites `python -m json.tool` to `jq .` |
| `rewrite-git-c.sh` | PreToolUse | rewrite | Rewrites `git -C <path>` to `cd <path> && git` |
| `gh-api-readonly.sh` | PreToolUse | deny | Requires `--method GET` on `gh api` calls |
| `gh-pr-reply.sh` | Helper | — | PR review comment reply script (installed to `~/.local/bin/`) |
| `post-git-push-watch.sh` | PostToolUse | watch | Monitors CI checks after `git push` / `gh pr create` |
| `statusline-starship.sh` | StatusLine | — | Shows branch, model, and context usage in status bar |

## Hook Details

### block-dangerous-flags.sh

Blocks commands that could cause data loss. Strips quoted strings before matching to avoid false positives.

**Blocked patterns:**
- `sed -i` / `sed --in-place` — in-place file editing
- `find` with `-delete`, `-exec`, `-execdir`, `-ok`, `-okdir`, `-fls`, `-fprint`
- `fd` with `-x`, `--exec`, `-X`, `--exec-batch`
- `sort -o` / `sort --output` — in-place file output
- `nix store delete|gc|repair|optimise` — destructive store operations
- `nix profile remove|wipe-history` — profile modification
- `nix-env --uninstall|--delete-generations|-e` — package removal

**Output:** `{ "decision": "deny", "reason": "..." }` or exits 0 (allow).

### git-readonly-approve.sh

Auto-approves read-only git commands so they don't require user confirmation.

**Approved subcommands:** `status`, `diff`, `log`, `show`, `branch`, `rev-parse`, `remote`, `tag`, `shortlog`, `describe`, `rev-list`, `ls-files`, `ls-tree`, `ls-remote`, `cat-file`, `name-rev`, `merge-base`, `count-objects`, `for-each-ref`, `blame`, `annotate`, `grep`, `version`, `help`

**Approved stash subcommands:** `list`, `show`

**Features:**
- Correctly parses global flags (`-C`, `-c`, `--git-dir`, `--work-tree`, etc.)
- Splits on `||`, `&&`, `;`, `|` and validates each segment independently
- Falls through (no output) for write operations

### prefer-deno.sh

When a Bash command contains `python` or `python3` (outside quoted strings), outputs a `systemMessage` suggesting Deno as a safer alternative due to its permission model.

### prefer-jq.sh

Detects `python3? -m json.tool` patterns (outside quoted strings) and rewrites the command to use `jq .` instead.

**Output:** `{ "tool_input": { "command": "<rewritten>" } }` or empty.

### rewrite-git-c.sh

Rewrites `git -C <path> <args>` to `cd <path> && git <args>` for better compatibility. Handles single-quoted, double-quoted, and unquoted paths, as well as pipes and chained commands.

### gh-api-readonly.sh

Denies `gh api` calls that don't include `-X GET` or `--method GET`. Provides a specific suggestion to use `gh-pr-reply` when PR review comment endpoints are detected.

### post-git-push-watch.sh

After `git push` or `gh pr create`, waits 3 seconds for CI pipelines to start, then runs `gh pr checks --watch --fail-fast` (timeout: 120s). Reports pass/fail via `systemMessage`.

### statusline-starship.sh

Generates an ANSI-colored status line showing:
- Current directory (with `~` expansion)
- Git branch (magenta)
- Model name (green)
- Context window usage percentage (yellow)

## Customization

Add custom hooks via `claude-hooks.nix` options:

```nix
takoeight0821.programs.claude-hooks = {
  enable = true;

  extraPreToolUseHooks = [
    {
      matcher = "Bash";
      hooks = [
        {
          type = "command";
          command = "bash ~/.claude/hooks/my-custom-hook.sh";
        }
      ];
    }
  ];

  extraPostToolUseHooks = [
    {
      matcher = "Edit|Write";
      hooks = [
        {
          type = "command";
          command = "echo 'File modified'";
        }
      ];
    }
  ];
};
```
