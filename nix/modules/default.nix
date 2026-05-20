# # Module root
#
# Aggregates the category sub-trees and provides a small piece of
# shared infrastructure that the per-program modules rely on:
#
# - `my.allowedUnfree` is the system-wide whitelist of unfree
#   packages. Modules that pull in unfree software push their
#   derivations onto this list rather than each one rewriting
#   `nixpkgs.config.allowUnfreePredicate` (which is a single
#   function and cannot be merged). Packages — not names — are
#   used so a typo surfaces at evaluation time instead of silently
#   denying an unfree package and rebuilding it from source.
{
  lib,
  config,
  ...
}: {
  imports = [
    ./drivers
    ./programs
    ./services
  ];

  options.my.allowedUnfree = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [];
    description = "Unfree packages explicitly permitted on this host.";
  };

  config.nixpkgs.config.allowUnfreePredicate = let
    whitelist = map lib.getName config.my.allowedUnfree;
  in
    pkg: builtins.elem (lib.getName pkg) whitelist;
}
