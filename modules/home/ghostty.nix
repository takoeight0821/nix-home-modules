{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.takoeight0821.programs.ghostty;
in
{
  options.takoeight0821.programs.ghostty = {
    enable = lib.mkEnableOption "Ghostty terminal configuration";
    fontFamily = lib.mkOption {
      type = lib.types.str;
      default = "HackGen Console NF";
      description = "Font family for Ghostty";
    };
    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 14;
      description = "Font size for Ghostty";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      package = null;
      settings = {
        font-family = cfg.fontFamily;
        font-size = cfg.fontSize;
        desktop-notifications = true;
        audible-bell = true;
      };
    };
  };
}
