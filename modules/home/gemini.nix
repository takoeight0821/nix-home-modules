{
  config,
  lib,
  nhm-lib,
  ...
}:
let
  cfg = config.takoeight0821.programs.gemini;
in
{
  options.takoeight0821.programs.gemini = {
    enable = lib.mkEnableOption "Gemini CLI configuration";
  };

  config = lib.mkIf cfg.enable {
    home.activation.geminiSettings = nhm-lib.mkMutableConfig {
      name = "gemini";
      configContent = builtins.toJSON {
        theme = "auto";
        privacy = {
          usageStatisticsEnabled = false;
        };
      };
      targetPath = ".gemini/settings.json";
    };
  };
}
