{
  description = "Basile's Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.url = "github:hraban/mac-app-util";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      mac-app-util,
      nix-homebrew,
      homebrew-bundle,
      homebrew-cask,
      homebrew-core,
    }:
    let
      configuration =
        {
          pkgs,
          config,
          lib,
          ...
        }:
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = with pkgs; [
            firefox

            # Development apps
            tmux
            zellij
            wezterm
            ghostty-bin
            podman

            # macOS does not let you natively configure different
            # scroll directions for trackpad & mouse...
            unnaturalscrollwheels

            # Messaging
            signal-desktop-bin

            # CAD
            openscad-unstable

            # Misc
            youtube-music
            musescore
            drawio
            the-unarchiver
          ];

          # Packages installed through brew
          homebrew = {
            enable = true;

            onActivation = {
              cleanup = "zap";
              # autoUpdate = true;
            };

            taps = [
              "homebrew/cask"
            ];

            casks = [
              "whatsapp"
              "launchcontrol"
            ];

            masApps = {
              # Bitwarden should be installed as a Mac App Store app to allow touch ID
              # authentication from Firefox.
              Bitwarden = 1352778147;
            };
          };

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Recurrent clean up & optimisation
          nix.gc.automatic = true;
          nix.optimise.automatic = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # Allow unfree apps:
          nixpkgs.config.allowUnfree = true;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          # See <https://github.com/nix-darwin/nix-darwin/blob/44a7d0e687a87b73facfe94fba78d323a6686a90/modules/system/primary-user.nix>
          system.primaryUser = "basile";
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .
      darwinConfigurations."macbook-air" = nix-darwin.lib.darwinSystem {
        modules = [
          ./services/yabai.nix
          ./services/srhd.nix
          ./services/kanata
          ./config/git.nix
          ./config/system.nix
          ./config/shell.nix
          ./config/direnv.nix
          ./config/dev
          configuration
          mac-app-util.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;

              # User owning the Homebrew prefix
              user = "basile";

              # Optional: Declarative tap management
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "homebrew/homebrew-bundle" = homebrew-bundle;
              };

              # Optional: Enable fully-declarative tap management
              #
              # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
              mutableTaps = false;
            };
          }
        ];
      };
    };
}
