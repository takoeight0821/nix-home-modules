{
  config,
  lib,
  nhm-lib,
  ...
}:
let
  cfg = config.takoeight0821.programs.codex;
in
{
  options.takoeight0821.programs.codex = {
    enable = lib.mkEnableOption "Codex configuration";
  };

  config = lib.mkIf cfg.enable {
    home.activation.codexConfig = nhm-lib.mkMutableConfig {
      name = "codex";
      configContent = ''model = "gpt-5.4"'';
      targetPath = ".codex/config.toml";
    };
  };
}
