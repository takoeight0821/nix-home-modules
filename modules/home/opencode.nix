{
  config,
  lib,
  pkgs,
  nhm-lib,
  ...
}:
let
  cfg = config.takoeight0821.programs.opencode;
in
{
  options.takoeight0821.programs.opencode = {
    enable = lib.mkEnableOption "opencode configuration";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.opencode ];

    home.activation.opencodeConfig = nhm-lib.mkMutableConfig {
      name = "opencode";
      configContent = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
      };
      targetPath = ".config/opencode/opencode.json";
    };
  };
}
