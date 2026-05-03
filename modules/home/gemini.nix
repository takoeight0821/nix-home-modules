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
        general = {
          sessionRetention = {
            enabled = true;
            warningAcknowledged = true;
            maxAge = "120d";
          };
        };
        security = {
          auth = {
            selectedType = "oauth-personal";
          };
        };
        tools = {
          sandbox = "sandbox-exec";
        };
      };
      targetPath = ".gemini/settings.json";
    };
  };
}
