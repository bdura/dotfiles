# # Signal
#
# Signal desktop client.
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.my.programs.signal;
in {
  options.my.programs.signal = {
    enable = mkEnableOption "Signal desktop client";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.signal-desktop];
    my.needsOzoneWayland = true;
  };
}
