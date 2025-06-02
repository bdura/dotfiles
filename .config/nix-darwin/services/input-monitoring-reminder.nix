# macos-input-monitoring-reminder.nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.macosInputMonitoringReminder;

  # List of packages that commonly require input monitoring permissions
  inputMonitoringPackages = with pkgs; [
    kanata
  ];

  # Function to check if any of the input monitoring packages are installed
  getInstalledPackages =
    packages:
    let
      allPackages = config.environment.systemPackages;
    in
    builtins.filter (pkg: builtins.elem pkg allPackages) packages;

  reminderScript =
    packages:
    let
      installedPackages = getInstalledPackages packages;
    in
    pkgs.writeShellScript "input-monitoring-reminder" ''
      #!/bin/bash

      # ANSI color codes
      RED='\033[0;31m'
      YELLOW='\033[1;33m'
      GREEN='\033[0;32m'
      BLUE='\033[0;34m'
      BOLD='\033[1m'
      NC='\033[0m' # No Color

      # Check if we have packages that need input monitoring
      packages=(${concatStringsSep " " (map (pkg: ''"${pkg}"'') installedPackages)})

      if [ ''${#packages[@]} -gt 0 ]; then
        echo ""
        echo -e "''${BOLD}''${YELLOW}⚠️  INPUT MONITORING PERMISSIONS REMINDER''${NC}"
        echo -e "''${BOLD}════════════════════════════════════════════''${NC}"
        echo ""
        echo -e "The following packages may require ''${BOLD}Input Monitoring''${NC} permissions:"
        echo ""

        for package in "''${packages[@]}"; do
          echo -e "  ''${BLUE}•''${NC} ''${package}"
        done

        echo ""
        echo -e "''${BOLD}To grant Input Monitoring permissions:''${NC}"
        echo -e "  1. Open ''${GREEN}System Settings''${NC} → ''${GREEN}Privacy & Security''${NC} → ''${GREEN}Input Monitoring''${NC}"
        echo -e "  2. Click the ''${BOLD}+''${NC} button and add the applications"
        echo -e "  3. Restart the applications after granting permissions"
        echo ""
        echo -e "''${BOLD}Alternative quick access:''${NC}"
        echo -e "  Run: ''${GREEN}open 'x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent'''${NC}"
        echo ""
        echo -e "''${YELLOW}Note:''${NC} This reminder appears when rebuilding your nix-darwin configuration"
        echo -e "      and can be disabled by setting ''${BOLD}services.macosInputMonitoringReminder.enable = false;''${NC}"
        echo ""
      fi
    '';

in
{
  options.services.macosInputMonitoringReminder = {
    enable = mkEnableOption "macOS Input Monitoring permissions reminder";

    additionalPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Additional packages to check for input monitoring requirements";
    };

    showOnEveryRebuild = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to show the reminder on every rebuild (true) or only when new packages are detected (false)";
    };
  };

  config =
    let
      packages = inputMonitoringPackages ++ cfg.additionalPackages;
      installedPackages = getInstalledPackages packages;
    in
    mkIf cfg.enable
    && (length installedPackages > 0) {
      # Use system.activationScripts for nix-darwin
      system.activationScripts.inputMonitoringReminder.text = ''
        echo "Checking for input monitoring permission requirements..."
        ${reminderScript installedPackages}
      '';
    };
}

# Usage example in your nix-darwin configuration:
#
# {
#   imports = [ ./macos-input-monitoring-reminder.nix ];
#
#   services.macosInputMonitoringReminder = {
#     enable = true;
#     additionalPackages = [ "my-custom-keylogger" "special-automation-tool" ];
#   };
#
#   # Your other packages that might need input monitoring
#   environment.systemPackages = with pkgs; [
#     # ... other packages
#   ];
#
#   homebrew = {
#     enable = true;
#     casks = [
#       "karabiner-elements"
#       "rectangle"
#       "raycast"
#       # ... other casks
#     ];
#   };
# }
