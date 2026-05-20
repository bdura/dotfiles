# # Slack
#
# Slack desktop client. The module wires up two pieces of state:
#
# - Adds the `slack` package to `environment.systemPackages`.
# - Registers `slack` with `my.allowedUnfree` (defined in
#   `modules/default.nix`) so the package is permitted under
#   nixpkgs' allow-unfree predicate without the host config having
#   to know Slack is unfree.
#
# `NIXOS_OZONE_WL = "1"` (which Slack relies on to render natively
# under Wayland) is intentionally NOT set here. It benefits every
# Electron app on the system — Obsidian, Bitwarden Desktop, etc. —
# so it lives in the host config; toggling Slack off should not
# also flip Wayland mode off for every other Chromium-based app.
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
  };
}
