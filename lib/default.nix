{ lib }:

{
  mkMutableConfig = import ./mkMutableConfig.nix { inherit lib; };
  convertPlugin = import ./convert-plugin.nix;
}
