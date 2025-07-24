{
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = [
    ./services/yabai.nix
    ./services/srhd.nix
    ./services/kanata
    ./config/git.nix
    ./config/system.nix
    ./config/shell.nix
    ./config/direnv.nix
    ./config/dev

  ];
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

    # Nix management
    nh
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

  services.tailscale.enable = true;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Recurrent clean up & optimisation
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 7d";
  };
  nix.optimise.automatic = true;

}
