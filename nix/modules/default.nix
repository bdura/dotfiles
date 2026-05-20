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
# - `my.needsOzoneWayland` collects packages that want
#   `NIXOS_OZONE_WL = "1"` to render natively under Wayland (mostly
#   Electron / Chromium apps). The env var is system-wide and
#   benefits every Chromium-based app, but exposing it as a
#   contributor list means the last consumer turning off also
#   turns the var off — and modules can self-declare their need
#   instead of the host config having to know which apps are
#   Electron under the hood. There is no reliable way to detect
#   this from a derivation (most Electron apps bundle their own
#   Electron binary, so `pkgs.electron` never appears in the
#   closure), which is why this is opt-in rather than introspected.
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
    needsOzoneWayland = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = ''
        Packages that require `NIXOS_OZONE_WL = "1"` to use native
        Wayland rendering. The env var is set system-wide whenever
        this list is non-empty.
      '';
    };
  };

  config = {
    nixpkgs.config.allowUnfreePredicate = let
      whitelist = map lib.getName config.my.allowedUnfree;
    in
      pkg: builtins.elem (lib.getName pkg) whitelist;

    environment.variables = lib.mkIf (config.my.needsOzoneWayland != []) {
      NIXOS_OZONE_WL = "1";
    };
  };
}
