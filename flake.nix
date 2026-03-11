{
  description = "Reusable home-manager and nix-darwin modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      homeManagerModules.default = import ./modules/home;

      darwinModules.default = import ./modules/darwin;

      lib =
        let
          raw = import ./lib { inherit (nixpkgs) lib; };
        in
        {
          inherit (raw) mkMutableConfig convertPlugin;
        };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          testHome =
            (home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                self.homeManagerModules.default
                {
                  home.username = "testuser";
                  home.homeDirectory = "/Users/testuser";
                  home.stateVersion = "24.11";
                  takoeight0821.programs.claude-hooks.enable = true;
                }
              ];
            }).config.home;
        in
        {
          test-block-dangerous-flags =
            pkgs.runCommand "test-block-dangerous-flags"
              {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.jq
                  pkgs.gnugrep
                  pkgs.gnused
                ];
              }
              ''
                HOOK_SCRIPT=$(mktemp)
                cat > "$HOOK_SCRIPT" <<'HOOKEOF'
                ${testHome.file.".claude/hooks/block-dangerous-flags.sh".text}
                HOOKEOF
                chmod +x "$HOOK_SCRIPT"
                bash ${./tests/test-block-dangerous-flags.sh} --script "$HOOK_SCRIPT"
                touch $out
              '';

          test-git-readonly-approve =
            pkgs.runCommand "test-git-readonly-approve"
              {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.jq
                  pkgs.gnugrep
                  pkgs.gnused
                ];
              }
              ''
                HOOK_SCRIPT=$(mktemp)
                cat > "$HOOK_SCRIPT" <<'HOOKEOF'
                ${testHome.file.".claude/hooks/git-readonly-approve.sh".text}
                HOOKEOF
                chmod +x "$HOOK_SCRIPT"
                bash ${./tests/test-git-readonly-approve.sh} --script "$HOOK_SCRIPT"
                touch $out
              '';

          test-rewrite-git-c =
            pkgs.runCommand "test-rewrite-git-c"
              {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.jq
                  pkgs.gnugrep
                  pkgs.gnused
                ];
              }
              ''
                HOOK_SCRIPT=$(mktemp)
                cat > "$HOOK_SCRIPT" <<'HOOKEOF'
                ${testHome.file.".claude/hooks/rewrite-git-c.sh".text}
                HOOKEOF
                chmod +x "$HOOK_SCRIPT"
                bash ${./tests/test-rewrite-git-c.sh} --script "$HOOK_SCRIPT"
                touch $out
              '';
        }
      );
    };
}
