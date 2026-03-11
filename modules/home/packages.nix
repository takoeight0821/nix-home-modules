{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.takoeight0821.programs.packages;
in
{
  options.takoeight0821.programs.packages = {
    enable = lib.mkEnableOption "Common packages";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional packages to install";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        # CLI tools
        ripgrep
        fd
        jq
        tree
        htop
        ghq
        pandoc

        # Development tools
        gh
        delta
        mise
        nil
        deno
        golangci-lint
        pinact
        actionlint
        coreutils

        # Cloud CLIs
        awscli2
        google-cloud-sdk
        azure-cli

        # File management
        trash-cli
      ]
      ++ cfg.extraPackages;
  };
}
