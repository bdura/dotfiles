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
#
# - `my.needsOzoneWayland` is a plain boolean toggle that any
#   module can flip to `true` to set `NIXOS_OZONE_WL = "1"`
#   system-wide. The env var enables native Wayland rendering for
#   Chromium / Electron apps (Slack, Obsidian, Bitwarden Desktop,
#   ...) instead of letting them fall back to XWayland. Multiple
#   modules setting the toggle to `true` merge cleanly under the
#   default `bool` merge function. The option is opt-in (rather
#   than introspected) because most Electron apps bundle their own
#   Electron binary, so `pkgs.electron` never appears in their
#   derivation closure and there is nothing reliable to detect.
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

  options.my = {
    allowedUnfree = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Unfree packages explicitly permitted on this host.";
    };
    needsOzoneWayland = lib.mkEnableOption "native Wayland rendering for Chromium / Electron apps (`NIXOS_OZONE_WL`)";
  };

  config = {
    nixpkgs.config.allowUnfreePredicate = let
      whitelist = map lib.getName config.my.allowedUnfree;
    in
      pkg: builtins.elem (lib.getName pkg) whitelist;

    environment.variables = lib.mkIf config.my.needsOzoneWayland {
      NIXOS_OZONE_WL = "1";
    };
  };
}
