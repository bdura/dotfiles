# # mistral-vibe
#
# Mistral's "vibe" CLI, wrapped so its state lives under
# `$XDG_CONFIG_HOME/vibe` rather than the upstream default.
#
# - Adds the wrapped `vibe` binary to `environment.systemPackages`,
#   alongside [`rtk`].
# - Applies a nixpkgs overlay that disables
#   `python313Packages.pytest-benchmark`'s test suite. Several packages
#   in vibe's closure (`pint`, `jsonpath-python`, ...) pull it in as a
#   check input, and its own `pytestCheckPhase` runs a ~8 minute
#   benchmark on every from-source rebuild. Disabling the check at the
#   leaf means it stays available as a dependency but builds instantly.
#
# [`rtk`]: https://github.com/rtk-ai/rtk
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
              pytest-benchmark = pyprev.pytest-benchmark.overridePythonAttrs (_: {doCheck = false;});
            })
          ];
      })
    ];
  };
}
