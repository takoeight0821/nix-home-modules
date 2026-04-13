{ lib, pkgs, ... }:
let
  nhm-lib-raw = import ../../lib { inherit lib; };
in
{
  _module.args.nhm-lib = {
    mkMutableConfig = nhm-lib-raw.mkMutableConfig pkgs;
    convertPlugin = nhm-lib-raw.convertPlugin { inherit pkgs lib; };
  };

  imports = [
    ./packages.nix
    ./neovim.nix
    ./shell.nix
    ./ghostty.nix
    ./iterm2
    ./tmux.nix
    ./vscode
    ./karabiner.nix
    ./codex.nix
    ./gemini.nix
    ./claude-hooks.nix
    ./claude-plugins.nix
  ];
}
