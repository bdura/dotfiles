# # Slack
#
# Slack desktop client.
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.my.programs.slack;
in {
  options.my.programs.slack = {
    enable = mkEnableOption "Slack desktop client";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.slack];
    my.allowedUnfree = [pkgs.slack];
    my.needsOzoneWayland = true;
  };
}
