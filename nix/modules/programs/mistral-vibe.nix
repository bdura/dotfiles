# # mistral-vibe
#
# Mistral's "vibe" CLI, wrapped so its state lives under
# `$XDG_CONFIG_HOME/vibe` rather than the upstream default.
#
# - Adds the wrapped `vibe` binary to `environment.systemPackages`,
#   alongside [`rtk`].
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
    runtimeInputs = with pkgs; [
      rtk
    ];
  };
in {
  options.my.programs.mistral-vibe = {
    enable = mkEnableOption "Mistral vibe CLI";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [vibe];

    my.allowedUnfree = [
      pkgs.python313Packages.textual-speedups
    ];
  };
}
