{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.takoeight0821.programs.claude-hooks;

  hookActionType = lib.types.submodule {
    options = {
      type = lib.mkOption {
        type = lib.types.str;
        default = "command";
      };
      command = lib.mkOption {
        type = lib.types.str;
      };
      timeout = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
      };
    };
  };

  claudeHookEntryType = lib.types.submodule {
    options = {
      matcher = lib.mkOption {
        type = lib.types.str;
      };
      hooks = lib.mkOption {
        type = lib.types.listOf hookActionType;
      };
    };
  };

  mkHookAction = action:
    { inherit (action) type command; }
    // lib.optionalAttrs (action.timeout != null) { inherit (action) timeout; };

  mkHookEntry = entry: {
    inherit (entry) matcher;
    hooks = map mkHookAction entry.hooks;
  };

  settingsJson = builtins.toJSON (
    {
      permissions = {
        allow =
          [
            "WebSearch"

            "Bash(git status:*)"
            "Bash(git diff:*)"
            "Bash(git log:*)"
            "Bash(git show:*)"
            "Bash(git branch:*)"
            "Bash(git rev-parse:*)"
            "Bash(git remote:*)"
            "Bash(git stash list:*)"
            "Bash(git tag:*)"

            "Bash(* --version)"
            "Bash(* --help)"

            "Bash(gh-pr-reply:*)"
            "Bash(gh pr view:*)"
            "Bash(gh pr list:*)"
            "Bash(gh pr diff:*)"
            "Bash(gh pr checks:*)"
            "Bash(gh issue view:*)"
            "Bash(gh issue list:*)"
            "Bash(gh repo view:*)"
            "Bash(gh api --method GET:*)"
            "Bash(gh run view:*)"
            "Bash(gh run list:*)"

            "Bash(nix build:*)"
            "Bash(nix develop:*)"
            "Bash(nix run:*)"
            "Bash(nix shell:*)"
            "Bash(nix flake:*)"
            "Bash(nix eval:*)"
            "Bash(nix search:*)"
            "Bash(nix path-info:*)"
            "Bash(nix why-depends:*)"
            "Bash(nix log:*)"
            "Bash(nix derivation show:*)"
            "Bash(nix config show:*)"
            "Bash(nix hash:*)"
            "Bash(nix registry:*)"
            "Bash(nix profile list:*)"
            "Bash(nix profile diff-closures:*)"
            "Bash(nix profile history:*)"
            "Bash(nix store cat:*)"
            "Bash(nix store diff-closures:*)"
            "Bash(nix store dump-path:*)"
            "Bash(nix store ls:*)"
            "Bash(nix store path-info:*)"
            "Bash(nix fmt:*)"
            "Bash(nixfmt:*)"
            "Bash(nix help:*)"
            "Bash(nix repl:*)"
            "Bash(nix-env --query:*)"
            "Bash(nix-env -q:*)"
            "Bash(nix-env --list-generations:*)"

            "Bash(brew list:*)"
            "Bash(brew info:*)"
            "Bash(brew search:*)"

            "Bash(cat:*)"
            "Bash(head:*)"
            "Bash(tail:*)"
            "Bash(echo:*)"
            "Bash(ls:*)"
            "Bash(pwd)"
            "Bash(dirname:*)"
            "Bash(basename:*)"
            "Bash(realpath:*)"
            "Bash(type:*)"

            "Bash(jq:*)"
            "Bash(rg:*)"
            "Bash(grep:*)"
            "Bash(diff:*)"
            "Bash(uniq:*)"
            "Bash(tr:*)"
            "Bash(cut:*)"
            "Bash(sed:*)"
            "Bash(find:*)"
            "Bash(fd:*)"
            "Bash(sort:*)"

            "Bash(file:*)"
            "Bash(stat:*)"
            "Bash(tree:*)"
            "Bash(du:*)"
            "Bash(df:*)"

            "Bash(date:*)"
            "Bash(printenv:*)"
            "Bash(uname:*)"

            "Bash(ghq list:*)"
            "Bash(code:*)"
            "Bash(which:*)"
            "Bash(wc:*)"
            "Bash(delta:*)"
            "Bash(tmux:*)"

            "mcp__aws__aws___search_documentation"
            "mcp__aws__aws___read_documentation"
            "mcp__aws__aws___recommend"
            "mcp__aws__aws___list_regions"
            "mcp__aws__aws___get_regional_availability"

            "WebFetch(domain:github.com)"
            "WebFetch(domain:raw.githubusercontent.com)"
            "WebFetch(domain:gist.github.com)"
            "WebFetch(domain:nixos.org)"
            "WebFetch(domain:nixos.wiki)"
            "WebFetch(domain:nix-darwin.github.io)"
            "WebFetch(domain:marketplace.visualstudio.com)"
            "WebFetch(domain:code.visualstudio.com)"
          ]
          ++ cfg.extraAllowPermissions;
        deny = [
          "Read(.env*)"
          "Read(secrets/**)"
        ] ++ cfg.extraDenyPermissions;
        ask = [ ];
      };
      statusLine = {
        type = "command";
        command = "bash ~/.claude/statusline-starship.sh";
      };
      enabledPlugins =
        {
          "claude-md-management@claude-plugins-official" = true;
          "code-review@claude-plugins-official" = true;
          "code-simplifier@claude-plugins-official" = true;
          "commit-commands@claude-plugins-official" = true;
          "feature-dev@claude-plugins-official" = true;
          "gopls-lsp@claude-plugins-official" = true;
          "hookify@claude-plugins-official" = false;
          "plugin-dev@claude-plugins-official" = true;
          "pr-review-toolkit@claude-plugins-official" = true;
          "ralph-loop@claude-plugins-official" = true;
          "security-guidance@claude-plugins-official" = true;
          "typescript-lsp@claude-plugins-official" = true;
        }
        // cfg.extraEnabledPlugins;
      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };
      teammateMode = "tmux";
      language = "日本語";
      cleanupPeriodDays = 365;
      hooks = {
        Notification = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "msg=$(cat | jq -r '.notification.message // \"Notification\"'); /usr/bin/osascript -e \"display notification \\\"$msg\\\" with title \\\"Claude Code\\\" sound name \\\"Glass\\\"\" &";
              }
            ];
          }
        ];
        PreToolUse =
          [
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = "bash ~/.claude/hooks/prefer-deno.sh";
                }
              ];
            }
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = "bash ~/.claude/hooks/prefer-jq.sh";
                }
              ];
            }
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = "bash ~/.claude/hooks/block-dangerous-flags.sh";
                }
              ];
            }
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = "bash ~/.claude/hooks/rewrite-git-c.sh";
                }
              ];
            }
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = "bash ~/.claude/hooks/git-readonly-approve.sh";
                }
              ];
            }
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = "bash ~/.claude/hooks/gh-api-readonly.sh";
                }
              ];
            }
          ]
          ++ (map mkHookEntry cfg.extraPreToolUseHooks);
        PostToolUse =
          [
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = "bash ~/.claude/hooks/post-git-push-watch.sh";
                  timeout = 120;
                }
              ];
            }
            {
              matcher = "Edit|Write";
              hooks = [
                {
                  type = "command";
                  command = "if echo \"$CLAUDE_FILE_PATHS\" | grep -q '\\.go$'; then go fmt ./... && go vet ./... && if command -v golangci-lint >/dev/null 2>&1; then golangci-lint run --new-from-rev=HEAD ./... 2>&1 | head -30; fi; fi";
                }
              ];
            }
            {
              matcher = "Edit|Write";
              hooks = [
                {
                  type = "command";
                  command = "if echo \"$CLAUDE_FILE_PATHS\" | grep -q '\\.ts$'; then pnpm dlx tsc --noEmit; fi";
                }
              ];
            }
          ]
          ++ (map mkHookEntry cfg.extraPostToolUseHooks);
      };
    }
    // cfg.extraSettings
  );

  claudeMdContent = ''
    # Global Claude Code Instructions

    ## Do not add shell comments to Bash commands

    When using the Bash tool, do not include shell comments (`#`).

    - No comment lines (e.g. `# setup`)
    - No inline comments (e.g. `ls -la # list files`)
    - Use the `description` parameter for command explanations instead

    ## Workflow Rules

    - 計画（plan）を求められたら、計画ファイルを書いて停止する。明示的に実装を指示されるまで実装に入らない。
    - rebase やコンフリクト解決時は、結果を必ず検証する。「already up to date」と仮定しない。

    ## System Configuration

    - Nix/home-manager で管理されているファイル（~/.config 以下の生成ファイルなど）は直接編集せず、Nix 設定ファイル側を編集する。

    ## GitHub Operations

    - GitHub 操作には `gh` CLI を優先する。手動の git アプローチ（git remote add + git push など）より `gh pr create`、`gh pr merge` 等を使う。
    - 認証には PAT を使う。GitHub Apps 認証は使わない。

    ## GitHub CLI Usage

    - 読み取り・書き込みともに `gh` を使用

    ## Go Development

    - Go コード変更後は lint 問題をすべて修正してからコミットする。
    - lint 警告を「既存の問題」として無視しない。指摘されたら修正する。
  ''
  + cfg.claudeMdExtra;
in
{
  options.takoeight0821.programs.claude-hooks = {
    enable = lib.mkEnableOption "Claude Code safety hooks and settings";
    extraAllowPermissions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional allow permissions for Claude Code";
    };
    extraDenyPermissions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional deny permissions for Claude Code";
    };
    extraPreToolUseHooks = lib.mkOption {
      type = lib.types.listOf claudeHookEntryType;
      default = [ ];
      description = "Additional PreToolUse hooks";
    };
    extraPostToolUseHooks = lib.mkOption {
      type = lib.types.listOf claudeHookEntryType;
      default = [ ];
      description = "Additional PostToolUse hooks";
    };
    extraEnabledPlugins = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      default = { };
      description = "Additional enabled plugins";
    };
    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional top-level settings to merge";
    };
    claudeMdExtra = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra content to append to ~/.claude/CLAUDE.md";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file.".claude/settings.json" = {
      text = settingsJson;
    };

    home.file.".claude/CLAUDE.md" = {
      text = claudeMdContent;
    };

    home.file.".claude/hooks/prefer-deno.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        set -euo pipefail
        INPUT=$(cat)
        COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

        STRIPPED=$(echo "$COMMAND" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

        if ! echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)python3?\b'; then
          exit 0
        fi

        jq -n '{
          systemMessage: "Consider using deno instead of python. Deno has a built-in permission model, making it safer for auto-approval."
        }'
        exit 0
      '';
    };

    home.file.".claude/hooks/prefer-jq.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        set -euo pipefail
        INPUT=$(cat)
        COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

        STRIPPED=$(echo "$COMMAND" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

        if ! echo "$STRIPPED" | grep -qE 'python3?[[:space:]]+-m[[:space:]]+json\.tool'; then
          exit 0
        fi

        NEW_COMMAND=$(echo "$COMMAND" | sed -E 's/python3?[[:space:]]+-m[[:space:]]+json\.tool/jq ./g')

        jq -n --arg cmd "$NEW_COMMAND" '{
          updatedInput: {
            command: $cmd
          }
        }'
        exit 0
      '';
    };

    home.file.".claude/hooks/block-dangerous-flags.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
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

        if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)sed\b' && \
           echo "$STRIPPED" | grep -qE '\s-[^\s]*i|\s--in-place\b'; then
          deny "sed -i (in-place edit) is not allowed. Use sed without -i to output to stdout."
        fi

        if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)find\b' && \
           echo "$STRIPPED" | grep -qE '\s-(delete|exec|execdir|ok|okdir|fls|fprint0?|fprintf)\b'; then
          deny "find with -delete/-exec/-execdir/-ok/-okdir/-fls/-fprint is not allowed. Use find for listing only."
        fi

        if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)fd\b' && \
           echo "$STRIPPED" | grep -qE '\s(-x|--exec|-X|--exec-batch)\b'; then
          deny "fd with --exec/--exec-batch is not allowed. Use fd for listing only."
        fi

        if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)sort\b' && \
           echo "$STRIPPED" | grep -qE '\s(-o|--output)\b'; then
          deny "sort -o (output to file) is not allowed. Use sort to output to stdout."
        fi

        if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)nix\b' && \
           echo "$STRIPPED" | grep -qE '\bstore\s+(delete|gc|repair|optimise)\b'; then
          deny "nix store delete/gc/repair/optimise is not allowed via auto-approve. Run manually if needed."
        fi

        if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)nix\b' && \
           echo "$STRIPPED" | grep -qE '\bprofile\s+(remove|wipe-history)\b'; then
          deny "nix profile remove/wipe-history is not allowed via auto-approve. Run manually if needed."
        fi

        if echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)nix-env\b' && \
           echo "$STRIPPED" | grep -qE '\s--(uninstall|delete-generations)\b|\s-e\b'; then
          deny "nix-env --uninstall/--delete-generations is not allowed via auto-approve. Run manually if needed."
        fi

        exit 0
      '';
    };

    home.file.".claude/hooks/gh-api-readonly.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        set -euo pipefail
        INPUT=$(cat)
        COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

        if ! echo "$COMMAND" | grep -qE '(^|\s|&&|\|\||;)gh\s+api\b'; then
          exit 0
        fi

        if echo "$COMMAND" | grep -qiE '(--method|-X)\s+GET\b'; then
          exit 0
        fi

        if echo "$COMMAND" | grep -qE '/pulls/[0-9]+/comments/[0-9]+/replies'; then
          REASON="gh api requires explicit --method GET. To reply to a PR review comment, use: gh-pr-reply <owner/repo> <pull_number> <comment_id> <body>"
        else
          REASON="gh api requires explicit --method GET. Add --method GET to use gh api."
        fi

        jq -n --arg reason "$REASON" '{
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $reason
          }
        }'
      '';
    };

    home.file.".local/bin/gh-pr-reply" = {
      executable = true;
      text = ''
        #!/bin/bash
        set -euo pipefail
        if [[ $# -ne 4 ]]; then
          echo "Usage: gh-pr-reply <owner/repo> <pull_number> <comment_id> <body>" >&2
          exit 1
        fi
        gh api --method POST \
          -H "Accept: application/vnd.github+json" \
          "/repos/$1/pulls/$2/comments/$3/replies" \
          -f body="$4"
      '';
    };

    home.file.".claude/hooks/rewrite-git-c.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        set -euo pipefail
        INPUT=$(cat)
        COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

        STRIPPED=$(echo "$COMMAND" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

        if ! echo "$STRIPPED" | grep -qE '(^|\s)git\s.*-C\b'; then
          exit 0
        fi

        NEW_COMMAND=$(echo "$COMMAND" | sed -E \
          -e "s/git[[:space:]]+-C[[:space:]]+('[^']*')[[:space:]]*/cd \1 \&\& git /g" \
          -e 's/git[[:space:]]+-C[[:space:]]+("[^"]*")[[:space:]]*/cd \1 \&\& git /g' \
          -e 's/git[[:space:]]+-C[[:space:]]+([^[:space:]|&;]+)[[:space:]]*/cd \1 \&\& git /g')

        if [[ "$NEW_COMMAND" == "$COMMAND" ]]; then
          exit 0
        fi

        jq -n --arg cmd "$NEW_COMMAND" '{
          updatedInput: {
            command: $cmd
          }
        }'
        exit 0
      '';
    };

    home.file.".claude/hooks/git-readonly-approve.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        INPUT=$(cat)
        COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

        STRIPPED=$(echo "$COMMAND" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

        SAFE_SUBCMDS=" status diff log show branch rev-parse remote tag shortlog describe rev-list ls-files ls-tree ls-remote cat-file name-rev merge-base count-objects for-each-ref blame annotate grep version help "
        SAFE_STASH=" list show "

        extract_subcmd() {
          local -a w
          read -ra w <<< "$1"
          [[ "''${w[0]:-}" == "git" ]] || return 1
          local i=1 n=''${#w[@]}
          while (( i < n )); do
            case "''${w[i]}" in
              -C|-c)                   (( i += 2 )) ;;
              --git-dir|--work-tree|--namespace|--exec-path)
                                       (( i += 2 )) ;;
              --git-dir=*|--work-tree=*|--namespace=*|--exec-path=*|--config-env=*)
                                       (( i += 1 )) ;;
              --no-pager|--paginate|-p|--bare|--no-replace-objects|--literal-pathspecs|--glob-pathspecs|--noglob-pathspecs|--icase-pathspecs|--no-optional-locks|--no-lazy-fetch|--no-advice)
                                       (( i += 1 )) ;;
              -*)                      return 1 ;;
              *)
                local sub="''${w[i]}"
                local next="''${w[i+1]:-}"
                if [[ "$sub" == "stash" ]]; then
                  echo "stash $next"
                else
                  echo "$sub"
                fi
                return 0
                ;;
            esac
          done
          return 1
        }

        is_safe_git() {
          local sub
          sub=$(extract_subcmd "$1") || return 1
          if [[ "$sub" == stash\ * ]]; then
            local stash_sub="''${sub#stash }"
            [[ "$SAFE_STASH" == *" $stash_sub "* ]] && return 0
            return 1
          fi
          [[ "$SAFE_SUBCMDS" == *" $sub "* ]]
        }

        NL=$'\n'
        work="$STRIPPED"
        work="''${work//||/$NL}"
        work="''${work//&&/$NL}"
        work="''${work//;/$NL}"
        work="''${work//|/$NL}"

        found_git=false

        while IFS= read -r seg; do
          seg="''${seg#"''${seg%%[![:space:]]*}"}"
          seg="''${seg%"''${seg##*[![:space:]]}"}"
          [[ -z "$seg" ]] && continue

          if [[ "$seg" == git || "$seg" == git[[:space:]]* ]]; then
            found_git=true
            if ! is_safe_git "$seg"; then
              exit 0
            fi
          else
            exit 0
          fi
        done <<< "$work"

        if $found_git; then
          jq -n '{
            hookSpecificOutput: {
              hookEventName: "PreToolUse",
              permissionDecision: "allow",
              permissionDecisionReason: "Readonly git command auto-approved (global flags detected)."
            }
          }'
        fi

        exit 0
      '';
    };

    home.file.".claude/hooks/post-git-push-watch.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        INPUT=$(cat)
        COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

        STRIPPED=$(echo "$COMMAND" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

        if ! echo "$STRIPPED" | grep -qE '(^|\s|&&|\|\||;)(git\s+push|gh\s+pr\s+create)\b'; then
          exit 0
        fi

        sleep 3

        CHECKS_OUTPUT=$(gh pr checks --watch --fail-fast 2>&1) || {
          jq -n --arg out "$CHECKS_OUTPUT" '{
            systemMessage: ("gh pr checks failed: " + $out)
          }'
          exit 0
        }

        jq -n --arg out "$CHECKS_OUTPUT" '{
          systemMessage: ("CI checks passed:\n" + $out)
        }'
        exit 0
      '';
    };

    home.file.".claude/statusline-starship.sh" = {
      executable = true;
      text = ''
        #!/bin/bash

        input=$(cat)

        cwd=$(echo "$input" | jq -r '.workspace.current_dir')
        project_dir=$(echo "$input" | jq -r '.workspace.project_dir')
        model=$(echo "$input" | jq -r '.model.display_name')
        output_style=$(echo "$input" | jq -r '.output_style.name')

        dir_display="''${cwd/#$HOME/~}"

        git_info=""
        if git -C "$cwd" rev-parse --git-dir &>/dev/null; then
            branch=$(git -C "$cwd" -c core.useBuiltinFSMonitor=false -c core.untrackedCache=false branch --show-current 2>/dev/null || git -C "$cwd" -c core.useBuiltinFSMonitor=false -c core.untrackedCache=false rev-parse --short HEAD 2>/dev/null)
            if [ -n "$branch" ]; then
                git_info=" $(printf '\033[35m')on$(printf '\033[0m') $(printf '\033[35m')''${branch}$(printf '\033[0m')"
            fi
        fi

        model_info=" $(printf '\033[32m')''${model}$(printf '\033[0m')"

        context_info=""
        used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
        remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
        if [ -n "$used_pct" ]; then
            used_int=$(printf "%.0f" "$used_pct")
            remaining_int=$(printf "%.0f" "$remaining_pct")
            context_info=" $(printf '\033[33m')[ctx:''${used_int}%]$(printf '\033[0m')"
        fi

        printf "$(printf '\033[36m')%s$(printf '\033[0m')%s%s%s%s" "$dir_display" "$git_info" "$model_info" "$context_info"
      '';
    };
  };
}
