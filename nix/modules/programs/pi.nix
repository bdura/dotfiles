# # Pi
#
# Pi coding agent, configured to use the `$XDG_CONFIG_HOME/pi`
# rather than the upstream default.
#
# - Adds the wrapped `pi` binary to `environment.systemPackages`,
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
  cfg = config.my.programs.pi;
  pi = wrappers.lib.wrapPackage {
    pkgs = pkgs;
    package = pkgs.pi-coding-agent;
    binName = "pi";
    env = {
      PI_CODING_AGENT_DIR = "$HOME/.config/pi";
    };
    runtimeInputs = with pkgs; [
      rtk
    ];
  };
in {
  options.my.programs.pi = {
    enable = mkEnableOption "Pi coding agent";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pi];
  };
}
