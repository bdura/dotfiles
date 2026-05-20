# # mistral-vibe
#
# Mistral's "vibe" CLI, wrapped so its state lives under
# `$XDG_CONFIG_HOME/vibe` rather than the upstream default.
#
# - Adds the wrapped `vibe` binary to `environment.systemPackages`,
#   alongside `rtk` (the sandbox-aware command wrapper that all
#   CLIs are routed through on this system).
# - Applies a nixpkgs overlay that disables `python313Packages.pint`'s
#   test suite. `pint` is a transitive dependency of mistral-vibe and
#   its check phase pulls in `pytest-benchmark`, running a multi-minute
#   benchmark on every from-source rebuild of vibe's closure. The
#   overlay is scoped to this module because no other package on the
#   system needs `pint`.
{
  lib,
  pkgs,
  wrappers,
  config,
  ...
}:
with lib; let
  cfg = config.my.programs.mistral-vibe;
  vibe = wrappers.lib.wrapPackage {
    pkgs = pkgs;
    package = pkgs.mistral-vibe;
    binName = "vibe";
    env = {
      VIBE_HOME = "$HOME/.config/vibe";
    };
  };
in {
  options.my.programs.mistral-vibe = {
    enable = mkEnableOption "Mistral vibe CLI";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      vibe
      pkgs.rtk
    ];

    my.allowedUnfree = [
      pkgs.python313Packages.textual-speedups
    ];

    nixpkgs.overlays = [
      (_final: prev: {
        pythonPackagesExtensions =
          prev.pythonPackagesExtensions
          ++ [
            (_pyfinal: pyprev: {
              pint = pyprev.pint.overridePythonAttrs (_: {doCheck = false;});
            })
          ];
      })
    ];
  };
}
