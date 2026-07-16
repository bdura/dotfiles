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
# - `my.permittedInsecurePackages` is a per-module allowlist for
#   `pname-version` strings that nixpkgs has marked insecure. Each
#   entry pairs the string with the derivation that requires it, so
#   the aggregator can assert at eval time that the pinned name is
#   still a direct input of that derivation. Upstream bumping the
#   insecure version therefore surfaces as a build-time assertion
#   failure rather than a silently stale allowlist entry.
#
# - `my.needsOzoneWayland` is a plain boolean toggle that any
#   module can flip to `true` to set `NIXOS_OZONE_WL = "1"`
#   system-wide. The env var enables native Wayland rendering for
#   Chromium / Electron apps.
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
    permittedInsecurePackages = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          package = lib.mkOption {
            type = lib.types.package;
            description = "Derivation that needs the insecure dependency; used to verify the entry is still current.";
          };
          insecureName = lib.mkOption {
            type = lib.types.str;
            example = "electron-39.8.10";
            description = "`pname-version` of the insecure dependency, matching `nixpkgs.config.permittedInsecurePackages`.";
          };
        };
      });
      default = [];
      description = "Insecure `pname-version` allowlist, each tagged with the package that requires it.";
    };
    needsOzoneWayland = lib.mkEnableOption "native Wayland rendering for Chromium / Electron apps (`NIXOS_OZONE_WL`)";
  };

  config = {
    nixpkgs.config.allowUnfreePredicate = let
      whitelist = map lib.getName config.my.allowedUnfree;
    in
      pkg: builtins.elem (lib.getName pkg) whitelist;

    # Feed the collected `insecureName`s into the upstream allowlist. The
    # string-shaped API here is exactly what nixpkgs expects; the tagged
    # submodule only exists so we can run the drift assertion below.
    nixpkgs.config.permittedInsecurePackages =
      map (e: e.insecureName) config.my.permittedInsecurePackages;

    # Drift check: every registered `insecureName` must still be referenced
    # by its associated package, so a stale entry surfaces as a rebuild-time
    # assertion instead of a silently unused string on the allowlist.
    #
    # We look for the dependency in two places, because packages wire in
    # insecure deps two different ways:
    #
    #   1. As a proper `buildInputs` element — the "clean" case. Matched
    #      using the same `${getName drv}-${drv.version}` shape nixpkgs
    #      uses internally, so a hit here is guaranteed to be what nixpkgs
    #      would classify as insecure.
    #
    #   2. As a store path spliced into a shell hook (`postBuild`,
    #      `installPhase`, etc.) — common for Electron apps, where the
    #      electron binary is copied and re-wrapped rather than declared
    #      as a build input. Matched by substring against every string-
    #      valued attr on `drvAttrs`. Store paths have the shape
    #      `/nix/store/<hash>-<pname>-<version>...`, so `hasInfix` on the
    #      `pname-version` is precise enough to avoid false positives.
    assertions = map (e: {
      assertion = let
        inputs =
          (e.package.buildInputs or [])
          ++ (e.package.nativeBuildInputs or [])
          ++ (e.package.propagatedBuildInputs or []);
        inputMatch = drv:
          (drv ? name)
          && (drv ? version)
          && "${lib.getName drv}-${drv.version}" == e.insecureName;
        directHit = lib.any inputMatch inputs;

        attrs = e.package.drvAttrs or {};
        stringMatch = attrName: let
          v = attrs.${attrName};
        in
          builtins.isString v && lib.hasInfix e.insecureName v;
        stringHit = lib.any stringMatch (builtins.attrNames attrs);
      in
        directHit || stringHit;
      message = "my.permittedInsecurePackages entry `${e.insecureName}` is neither a direct input nor a store-path reference in `${e.package.name}`. Update the version or drop the entry.";
    }) config.my.permittedInsecurePackages;

    environment.variables = lib.mkIf config.my.needsOzoneWayland {
      NIXOS_OZONE_WL = "1";
    };
  };
}
