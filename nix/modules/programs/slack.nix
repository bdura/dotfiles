# # Slack
#
# Slack desktop client. The module wires up three pieces of state:
#
# - Adds the `slack` package to `environment.systemPackages`.
# - Registers `slack` with `my.allowedUnfree` (defined in
#   `modules/default.nix`) so the package is permitted under
#   nixpkgs' allow-unfree predicate without the host config having
#   to know Slack is unfree.
# - Registers `slack` with `my.needsOzoneWayland`, which causes
#   `NIXOS_OZONE_WL = "1"` to be set system-wide. Slack relies on
#   it to render natively under Wayland (otherwise it falls back
#   to XWayland and screen-share / global shortcuts misbehave).
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
    my.needsOzoneWayland = [pkgs.slack];
  };
}
