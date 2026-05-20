# # File Manager
#
# Thunar plus the storage services it leans on. Everything here is
# coupled — disabling any one piece breaks user-visible behaviour in
# the others — so they live behind a single switch.
#
# - `programs.thunar` is the file manager itself.
# - `thunar-archive-plugin` adds "Extract here" / "Create archive"
#   entries to the right-click menu (delegates to `file-roller` /
#   `xarchiver` / etc. at runtime).
# - `thunar-volman` ("volume manager") reacts to hotplug events and
#   auto-mounts inserted media. It is a frontend to udisks2 — without
#   `services.udisks2` below, it silently does nothing.
# - `services.gvfs` (GNOME Virtual File System) exposes non-local
#   filesystems through Thunar's sidebar: MTP phones, SMB/SFTP/WebDAV
#   shares, and the freedesktop `trash://` spec. In particular,
#   "Move to Trash" in Thunar requires gvfs — without it the action
#   is missing or silently fails.
# - `services.udisks2` is the DBus daemon that lets unprivileged users
#   mount removable drives by clicking them in Thunar (and is what
#   `udisksctl` talks to from the CLI).
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.my.services.file-manager;
in {
  options.my.services.file-manager = {
    enable = mkEnableOption "Thunar + gvfs + udisks2 file management stack";
  };

  config = mkIf cfg.enable {
    programs.thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-volman
      ];
    };

    services.gvfs.enable = true;
    services.udisks2.enable = true;
  };
}
