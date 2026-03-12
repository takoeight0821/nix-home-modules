{
  config,
  lib,
  pkgs,
  nhm-lib,
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

  mkHookAction =
    action:
    {
      inherit (action) type command;
    }
    // lib.optionalAttrs (action.timeout != null) { inherit (action) timeout; };

  mkHookEntry = entry: {
    inherit (entry) matcher;
    hooks = map mkHookAction entry.hooks;
  };

  settingsJson = builtins.toJSON (
    {
      permissions = {
        allow = [
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
        ]
        ++ cfg.extraDenyPermissions;
        ask = [ ];
      };
      statusLine = {
        type = "command";
        command = "bash ~/.claude/statusline-starship.sh";
      };
      enabledPlugins = {
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
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "bash ~/.claude/hooks/log-wrapper.sh prefer-deno ~/.claude/hooks/prefer-deno.sh";
              }
            ];
          }
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "bash ~/.claude/hooks/log-wrapper.sh prefer-jq ~/.claude/hooks/prefer-jq.sh";
              }
            ];
          }
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "bash ~/.claude/hooks/log-wrapper.sh block-dangerous-flags ~/.claude/hooks/block-dangerous-flags.sh";
              }
            ];
          }

          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "bash ~/.claude/hooks/log-wrapper.sh git-readonly-approve ~/.claude/hooks/git-readonly-approve.sh";
              }
            ];
          }
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "bash ~/.claude/hooks/log-wrapper.sh gh-api-readonly ~/.claude/hooks/gh-api-readonly.sh";
              }
            ];
          }
        ]
        ++ (map mkHookEntry cfg.extraPreToolUseHooks);
        PostToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "bash ~/.claude/hooks/log-wrapper.sh post-git-push-watch ~/.claude/hooks/post-git-push-watch.sh";
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
    home.activation.claudeSettings =
      let
        targetPath = ".claude/settings.json";
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        configFile="$HOME/${targetPath}"
        baselineFile="$HOME/${targetPath}.nix-baseline"
        mkdir -p "$(dirname "$configFile")"

        if [ -L "$configFile" ]; then
          rm "$configFile"
        fi

        newContent=$(${pkgs.jq}/bin/jq . <<'NIXJSONEOF'
${settingsJson}
NIXJSONEOF
)

        if [ ! -f "$baselineFile" ] || [ "$(cat "$baselineFile")" != "$newContent" ]; then
          if [ -f "$configFile" ] && [ -f "$baselineFile" ]; then
            if ! ${pkgs.diffutils}/bin/diff -q "$baselineFile" "$configFile" > /dev/null 2>&1; then
              echo "WARNING [claude-settings]: runtime changes will be overwritten by updated Nix config:"
              ${pkgs.diffutils}/bin/diff -u "$baselineFile" "$configFile" || true
            fi
          fi
          echo "$newContent" > "$configFile"
          echo "$newContent" > "$baselineFile"
        fi
      '';

    home.file.".claude/CLAUDE.md" = {
      text = claudeMdContent;
    };

    home.file.".claude/hooks/log-wrapper.sh" = {
      executable = true;
      text = builtins.readFile ./hooks/log-wrapper.sh;
    };

    home.file.".claude/hooks/prefer-deno.sh" = {
      executable = true;
      text = builtins.readFile ./hooks/prefer-deno.sh;
    };

    home.file.".claude/hooks/prefer-jq.sh" = {
      executable = true;
      text = builtins.readFile ./hooks/prefer-jq.sh;
    };

    home.file.".claude/hooks/block-dangerous-flags.sh" = {
      executable = true;
      text = builtins.readFile ./hooks/block-dangerous-flags.sh;
    };

    home.file.".claude/hooks/gh-api-readonly.sh" = {
      executable = true;
      text = builtins.readFile ./hooks/gh-api-readonly.sh;
    };

    home.file.".local/bin/gh-pr-reply" = {
      executable = true;
      text = builtins.readFile ./hooks/gh-pr-reply.sh;
    };

    home.file.".claude/hooks/git-readonly-approve.sh" = {
      executable = true;
      text = builtins.readFile ./hooks/git-readonly-approve.sh;
    };

    home.file.".claude/hooks/post-git-push-watch.sh" = {
      executable = true;
      text = builtins.readFile ./hooks/post-git-push-watch.sh;
    };

    home.file.".claude/statusline-starship.sh" = {
      executable = true;
      text = builtins.readFile ./hooks/statusline-starship.sh;
    };
  };
}
