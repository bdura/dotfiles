# # Printing
#
# CUPS plus the bits needed for network printer discovery. As with
# the file-manager module, the pieces are coupled in practice:
# `cups-browsed` will not find anything without an mDNS responder
# running, so avahi is bundled in.
#
# - `services.printing` enables CUPS — the print daemon and its
#   admin web UI on <http://localhost:631>.
# - `cups-filters` is the modern conversion pipeline (PDF in,
#   raster/PWG out) that most non-PostScript printers actually need.
# - `cups-browsed` watches the LAN for shared / IPP / AirPrint
#   printers advertised over mDNS and surfaces them to CUPS as
#   local queues so no manual driver setup is required.
# - `services.avahi` is the mDNS/DNS-SD responder. `cups-browsed`
#   talks to it to discover printers; `nssmdns4` also makes the
#   machine resolve `*.local` hostnames. `openFirewall = true`
#   opens UDP/5353 so inbound discovery traffic isn't dropped.
#
# Note: avahi is broader than printing (any `*.local` resolution
# benefits from it). It lives here because the firewall hole +
# nssmdns wiring exists specifically to make networked printing
# work without per-printer configuration; if you ever want mDNS
# without CUPS, split it back out.
#
# The `lp` group membership that lets a user submit print jobs is
# set per-user in `users.nix`, not here, since the module has no
# opinion on which accounts should be allowed to print.
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.my.services.printing;
in {
  options.my.services.printing = {
    enable = mkEnableOption "CUPS printing stack + mDNS printer discovery";
  };

  config = mkIf cfg.enable {
    services.printing = {
      enable = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
      ];
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    environment.systemPackages = [
      pkgs.simple-scan
    ];
  };
}
