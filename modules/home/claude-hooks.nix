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

  reservedHookEvents = [
    "PreToolUse"
    "PostToolUse"
    "Stop"
    "Notification"
  ];

  validatedExtraHookEntries =
    let
      invalid = lib.filter (e: builtins.elem e reservedHookEvents) (
        builtins.attrNames cfg.extraHookEntries
      );
    in
    assert lib.assertMsg (invalid == [ ])
      "extraHookEntries contains reserved event(s): ${builtins.concatStringsSep ", " invalid}. Use dedicated options instead.";
    cfg.extraHookEntries;

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
          "Bash(gh run watch:*)"

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
          "Read(~/.claude/**)"
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
      enabledPlugins = { } // cfg.extraEnabledPlugins;
      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };
      teammateMode = "auto";
      language = "Japanese";
      enableVoice = true;
      autoUpdatesChannel = "latest";
      hooks = {
        PreToolUse = [
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
                command = "bash ~/.claude/hooks/log-wrapper.sh prefer-rg ~/.claude/hooks/prefer-rg.sh";
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
        Notification = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "bash ~/.claude/hooks/notify-osc9.sh";
              }
            ];
          }
        ];
      }
      // lib.optionalAttrs (cfg.extraStopHooks != [ ]) {
        Stop = map mkHookEntry cfg.extraStopHooks;
      }
      // lib.mapAttrs (_event: entries: map mkHookEntry entries) validatedExtraHookEntries;
    }
    // cfg.extraSettings
  );

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
    extraStopHooks = lib.mkOption {
      type = lib.types.listOf claudeHookEntryType;
      default = [ ];
      description = "Additional Stop hooks";
    };
    extraHookEntries = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf claudeHookEntryType);
      default = { };
      description = "Additional hook entries keyed by event name (e.g. SessionStart, SessionEnd). Reserved events (PreToolUse, PostToolUse, Stop, Notification) are not allowed — use dedicated options instead.";
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

    home.file.".claude/hooks/log-wrapper.sh" = {
      executable = true;
      text = builtins.readFile ./hooks/log-wrapper.sh;
    };

    home.file.".claude/hooks/prefer-jq.sh" = {
      executable = true;
      text = builtins.readFile ./hooks/prefer-jq.sh;
    };

    home.file.".claude/hooks/prefer-rg.sh" = {
      executable = true;
      text = builtins.readFile ./hooks/prefer-rg.sh;
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

    home.file.".claude/hooks/notify-osc9.sh" = {
      executable = true;
      text = builtins.readFile ./hooks/notify-osc9.sh;
    };

    home.file.".claude/statusline-starship.sh" = {
      executable = true;
      text = builtins.readFile ./hooks/statusline-starship.sh;
    };
  };
}
