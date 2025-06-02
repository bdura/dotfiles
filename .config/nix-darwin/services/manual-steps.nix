{ config, lib, ... }:

with lib;

let
  cfg = config.services.manualActions;

  # Type definitions for manual actions
  manualActionType = types.submodule {
    options = {
      package = mkOption {
        type = types.package;
        description = "The Nix package that requires manual action";
      };

      inputMonitoring = mkOption {
        type = types.bool;
        default = false;
        description = "Whether the package requires Input Monitoring permissions on macOS";
      };

      accessibility = mkOption {
        type = types.bool;
        default = false;
        description = "Whether the package requires Accessibility permissions on macOS";
      };

      fullDiskAccess = mkOption {
        type = types.bool;
        default = false;
        description = "Whether the package requires Full Disk Access permissions on macOS";
      };

      screenRecording = mkOption {
        type = types.bool;
        default = false;
        description = "Whether the package requires Screen Recording permissions on macOS";
      };

      additionalSteps = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of additional manual steps required for this package";
      };

      description = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional description explaining why these permissions are needed";
      };
    };
  };

  # Function to generate permission messages
  generatePermissionMessage =
    action:
    let
      packageName = action.package.pname or (builtins.parseDrvName action.package.name).name;
      permissions =
        [ ]
        ++ optional action.inputMonitoring "Input Monitoring"
        ++ optional action.accessibility "Accessibility"
        ++ optional action.fullDiskAccess "Full Disk Access"
        ++ optional action.screenRecording "Screen Recording";

      permissionText =
        if permissions != [ ] then
          "  → Grant ${concatStringsSep ", " permissions} permission(s) in System Preferences > Security & Privacy"
        else
          "";

      additionalText =
        if action.additionalSteps != [ ] then
          concatMapStrings (step: "  → ${step}\n") action.additionalSteps
        else
          "";

      descriptionText = if action.description != null then "    (${action.description})\n" else "";
    in
    ''
      📦 ${packageName}:
      ${optionalString (permissionText != "") "${permissionText}\n"}${additionalText}${descriptionText}'';

  # Generate the complete reminder message
  reminderMessage =
    let
      activePackages = filter (
        action:
        action.inputMonitoring
        || action.accessibility
        || action.fullDiskAccess
        || action.screenRecording
        || action.additionalSteps != [ ]
      ) cfg.packages;
    in
    if activePackages == [ ] then
      ""
    else
      ''

        ═══════════════════════════════════════════════════════════════
        🔧 MANUAL ACTIONS REQUIRED
        ═══════════════════════════════════════════════════════════════

        The following packages require manual configuration:

        ${concatMapStrings generatePermissionMessage activePackages}
        For macOS permissions: System Preferences > Security & Privacy

        ═══════════════════════════════════════════════════════════════
      '';

in
{
  options.services.manualActions = {
    enable = mkEnableOption "manual actions reminder service";

    packages = mkOption {
      type = types.listOf manualActionType;
      default = [ ];
      description = "List of packages that require manual actions";
      example = literalExpression ''
        [
          {
            package = pkgs.kanata;
            inputMonitoring = true;
            additionalSteps = ["Run `sudo kanata --check`"];
            description = "Keyboard remapping requires system-level access";
          }
          {
            package = pkgs.rectangle;
            accessibility = true;
            description = "Window management requires accessibility permissions";
          }
        ]
      '';
    };

    showOnEveryRebuild = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to show reminders on every rebuild (true) or only when packages change (false)";
    };

    colorOutput = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to use colored output in terminal";
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.manualActionsReminder.text =
      let
        colorReset = if cfg.colorOutput then "\\033[0m" else "";
        colorBold = if cfg.colorOutput then "\\033[1m" else "";
        colorYellow = if cfg.colorOutput then "\\033[1;33m" else "";
        colorBlue = if cfg.colorOutput then "\\033[1;34m" else "";

        # Create a state file to track if we've shown the message for current config
        stateDir = "/var/lib/nix-darwin-manual-actions";
        configHash = builtins.hashString "sha256" (toString cfg.packages);
        stateFile = "${stateDir}/${configHash}";

        shouldShow = cfg.showOnEveryRebuild || "[ ! -f ${stateFile} ]";

        coloredMessage =
          if cfg.colorOutput then
            builtins.replaceStrings
              [
                "═══════════════════════════════════════════════════════════════"
                "🔧 MANUAL ACTIONS REQUIRED"
                "📦 "
              ]
              [
                "${colorYellow}═══════════════════════════════════════════════════════════════${colorReset}"
                "${colorBold}${colorYellow}🔧 MANUAL ACTIONS REQUIRED${colorReset}"
                "${colorBlue}📦 ${colorReset}"
              ]
              reminderMessage
          else
            reminderMessage;

      in
      mkIf (cfg.packages != [ ]) ''
        if ${shouldShow}; then
          echo -e "${coloredMessage}"
          mkdir -p ${stateDir}
          touch ${stateFile}
        fi
      '';
  };
}
