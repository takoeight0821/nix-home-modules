{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.takoeight0821.darwin.defaults;
in
{
  options.takoeight0821.darwin.defaults = {
    enable = lib.mkEnableOption "macOS system defaults and Homebrew";
    extraBrews = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional Homebrew formulae";
    };
    extraCasks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional Homebrew casks";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zsh.enable = true;

    system.defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };
      finder = {
        AppleShowAllExtensions = true;
        ShowPathbar = true;
        ShowStatusBar = true;
      };
      dock = {
        autohide = true;
        show-recents = false;
      };
    };

    system.keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
      };
      taps = [ ];
      brews =
        [
          "aws-sam-cli"
          "gemini-cli"
        ]
        ++ cfg.extraBrews;
      casks =
        [
          "ghostty"
          "visual-studio-code"
          "orbstack"

          "claude"
          "codex"
          "antigravity"

          "iterm2"

          "raycast"
          "microsoft-edge"
          "karabiner-elements"
          "logseq"

          "font-hackgen"
          "font-hackgen-nerd"
        ]
        ++ cfg.extraCasks;
    };
  };
}
