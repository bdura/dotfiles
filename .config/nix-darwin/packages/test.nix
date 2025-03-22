# default.nix

let
  pkgs = import <nixpkgs> { };
in
{
  karabiner-driverkit = pkgs.callPackage ./karabiner-driverkit.nix { };
}
