{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.takoeight0821.programs.shell;
in
{
  options.takoeight0821.programs.shell = {
    enable = lib.mkEnableOption "Shell (zsh) configuration";
    darwinRebuildFlakeRef = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Flake reference for darwin-rebuild (e.g. '/path/to/config#primary')";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;

      history = {
        size = 50000;
        save = 50000;
        ignoreDups = true;
        ignoreAllDups = true;
        ignoreSpace = true;
        share = true;
      };

      shellAliases = {
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";

        ls = "ls --color=auto";
        ll = "ls -la";
        la = "ls -a";
        l = "ls -CF";

        g = "git";
        gs = "git status";
        gd = "git diff";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gl = "git pull";

        wip = ''git commit --fixup $(git log -1 --pretty=format:"%H" --grep="^fixup\!" --invert-grep)'';

        npm = "echo 'Use pnpm instead of npm'; false";
        npx = "echo 'Use pnpm dlx instead of npx'; false";

        grep = "grep --color=auto";

        hooklog = "less +F ~/.claude/hooks.log";
      }
      // lib.optionalAttrs (cfg.darwinRebuildFlakeRef != "") {
        nrs = "darwin-rebuild switch --flake ${cfg.darwinRebuildFlakeRef}";
        nrb = "darwin-rebuild build --flake ${cfg.darwinRebuildFlakeRef}";
      };

      sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
        TMUX_TMPDIR = "${config.home.homeDirectory}/.tmux/sockets";
        CLAUDE_CODE_DISABLE_1M_CONTEXT = "1";
      };

      initContent = ''
        # Vi mode
        bindkey -v

        # Vi mode key bindings (Emacs-style in insert mode)
        bindkey -M viins '^A' beginning-of-line
        bindkey -M viins '^E' end-of-line
        bindkey -M viins '^G' send-break
        bindkey -M viins '^K' kill-line

        # Enable command correction
        setopt CORRECT
        setopt CORRECT_ALL

        # Better completion
        setopt AUTO_MENU
        setopt COMPLETE_IN_WORD
        setopt ALWAYS_TO_END

        # Directory stack
        setopt AUTO_PUSHD
        setopt PUSHD_IGNORE_DUPS
        setopt PUSHD_SILENT

        # Add local bin to PATH
        export PATH="$HOME/.local/bin:$PATH"

        # Initialize completions
        autoload -Uz compinit && compinit

        # mise (runtime version manager)
        eval "$(mise activate zsh)"

        # FZF-based repository navigation using ghq
        function fzf-src() {
          if command -v ghq &> /dev/null && command -v fzf &> /dev/null; then
            local src=$(ghq list --full-path | fzf --query "$LBUFFER")
            if [ -n "$src" ]; then
              BUFFER="cd '$src'"
              zle accept-line
            fi
            zle -R -c
          fi
        }

        # FZF-based code search with ripgrep
        function fzf-code() {
          if command -v rg &> /dev/null && command -v fzf &> /dev/null; then
            local file
            local line
            local query="''${LBUFFER:-.}"

            read -r file line <<<"$(rg --no-heading --line-number $query | fzf -0 -1 | awk -F: '{print $1, $2}')"

            if [[ -n $file ]]; then
              if command -v code &> /dev/null; then
                BUFFER="code --goto '$file:$line'"
              else
                BUFFER="''${EDITOR:-vim} +'$line' '$file'"
              fi
              zle accept-line
            fi
            zle -R -c
          fi
        }

        # Get a web page and copy it as markdown
        function copymd() {
          if command -v curl &> /dev/null && command -v pandoc &> /dev/null && command -v pbcopy &> /dev/null; then
            curl -s $1 | pandoc -f html -t markdown | pbcopy
          else
            echo "Error: Missing required tools (curl, pandoc, or pbcopy)"
            return 1
          fi
        }

        # Register custom functions as ZLE widgets and bind keys
        zle -N fzf-src
        bindkey -M viins '^]' fzf-src

        zle -N fzf-code
        bindkey -M viins '^f' fzf-code

        # VS Code settings diff check
        vscode-settings-diff() {
          local settings="$HOME/Library/Application Support/Code/User/settings.json"
          local baseline="$HOME/Library/Application Support/Code/User/settings.json.nix-baseline"
          if [[ -f "$baseline" ]]; then
            diff <(jq -S . "$settings") <(jq -S . "$baseline")
          else
            echo "No baseline file found. Run darwin-rebuild first."
            return 1
          fi
        }

        # darwin-rebuild wrapper that checks VS Code settings diff first
        darwin-rebuild() {
          local settings="$HOME/Library/Application Support/Code/User/settings.json"
          local baseline="$HOME/Library/Application Support/Code/User/settings.json.nix-baseline"

          # Only check if both files exist and command is 'switch'
          if [[ -f "$settings" && -f "$baseline" && "$1" == "switch" ]]; then
            if ! diff -q <(jq -S . "$settings") <(jq -S . "$baseline") > /dev/null 2>&1; then
              echo "Warning: VS Code settings.json has uncommitted changes:"
              diff <(jq -S . "$settings") <(jq -S . "$baseline") || true
              echo ""
              echo -n "Continue with darwin-rebuild? (y/N): "
              read -r answer
              if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
                echo "Aborted. Please sync your VS Code settings to vscode.nix first."
                return 1
              fi
            fi
          fi

          command darwin-rebuild "$@"
        }
      '';
    };

    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        command_timeout = 2000;
        gcloud = {
          disabled = true;
        };
      };
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
