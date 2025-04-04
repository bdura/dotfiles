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
            btop
            fzf
            git
            git-lfs
            lazygit
            mkalias
            neovim
            nixfmt-rfc-style
            pre-commit
            ripgrep
            starship
            signal-desktop
            tmux
            unnaturalscrollwheels
            wezterm
            youtube-music
            zoxide
            # Neovim
            # treesitter
            cmake
            lua
            luarocks
            imagemagick # Image conversion
            ghostscript # PDF files
            tectonic # Render LaTeX expressions
            mermaid-cli # Render mermaid diagrams
            fd # Faster find
            # latexmk
            # bibtex
            biber
            skhd
          ];

          fonts.packages = with pkgs; [
            nerd-fonts.jetbrains-mono
          ];

          # Packages installed through brew
          homebrew = {
            enable = true;

            onActivation = {
              cleanup = "zap";
              # autoUpdate = true;
            };

            casks = [
              "bitwarden"
              "the-unarchiver"
              "whatsapp"
              "launchcontrol"
            ];
          };

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Recurrent clean up & optimisation
          nix.gc.automatic = true;
          nix.optimise.automatic = true;

          programs = {
            zsh.enable = true;
            direnv.enable = true;
          };

          security.pam.services.sudo_local.touchIdAuth = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          time.timeZone = "Europe/Paris";

          system.startup.chime = false;
          system.defaults = {
            screencapture.target = "clipboard";
            # Faster transitions
            # universalaccess.reduceMotion = true;
            loginwindow.GuestEnabled = false;
            # Each display has its own spaces
            spaces.spans-displays = false;
            menuExtraClock = {
              Show24Hour = true;
              ShowSeconds = true;
            };
            finder = {
              FXPreferredViewStyle = "Nlsv";
              ShowPathbar = true;
              ShowStatusBar = true;
            };
            NSGlobalDomain = {
              AppleICUForce24HourTime = true;
              AppleInterfaceStyle = "Dark";
              "com.apple.mouse.tapBehavior" = 1;
              # Natural scroll direction
              "com.apple.swipescrolldirection" = true;
              NSAutomaticSpellingCorrectionEnabled = false;
              # Auto-hide menu bar. Useful if we use sketchybar
              _HIHideMenuBar = false;
              KeyRepeat = 2;
            };
            trackpad = {
              TrackpadThreeFingerDrag = true;
              # tap to click
              Clicking = true;
              # two-finger-tap right click
              TrackpadRightClick = true;
            };
            # Disable most recently used apps in the dock
            dock.mru-spaces = false;
          };

          # Allow unfree apps:
          nixpkgs.config.allowUnfree = true;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
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
