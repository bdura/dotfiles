{
  inputs,
  pkgs,
  host,
  username,
  options,
  ...
}: {
  imports = [
    ./hardware.nix
    ./storage.nix
    ./users.nix
    ./envvar.nix
    ./startup.nix
    ../../config/direnv.nix
    ../../config/git.nix
    ../../config/dev.nix
    ../../modules
  ];
  # Styling Options
  stylix = {
    enable = true;
    enableReleaseChecks = false;
    # Taken from <https://www.reddit.com/r/space/comments/11jburq/i_took_an_absurdly_high_resolution_photo_of_the/>
    image = ../../config/wallpapers/gigamoon.jpg;
    # TODO: use the name? [This](https://stylix.danth.me/configuration.html#handmade-schemes)
    # looks like it's broken.
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    base16Scheme = {
      base00 = "1A1B26";
      base01 = "16161E";
      base02 = "2F3549";
      base03 = "444B6A";
      base04 = "787C99";
      base05 = "A9B1D6";
      base06 = "CBCCD1";
      base07 = "D5D6DB";
      base08 = "f38ba8";
      base09 = "A9B1D6";
      base0A = "0DB9D7";
      base0B = "9ECE6A";
      base0C = "B4F9F8";
      base0D = "2AC3DE";
      base0E = "BB9AF7";
      base0F = "F7768E";
    };
    polarity = "dark";
    opacity.terminal = 1.0;
    cursor.package = pkgs.bibata-cursors;
    cursor.name = "Bibata-Modern-Ice";
    cursor.size = 24;
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.roboto;
        name = "Roboto";
      };
      serif = {
        package = pkgs.roboto;
        name = "Roboto";
      };
      sizes = {
        applications = 12;
        terminal = 15;
        desktop = 11;
        popups = 12;
      };
    };
  };

  my.drivers.intel.enable = true;
  my.services.file-manager.enable = true;
  my.services.printing.enable = true;
  my.programs.bitwarden.enable = true;
  my.programs.claude.enable = true;
  my.programs.mistral-vibe.enable = true;
  my.programs.neovim.enable = true;
  my.programs.slack.enable = true;

  # Enable networking
  networking.networkmanager.enable = true;
  networking.hostName = host;
  networking.timeServers = options.networking.timeServers.default ++ ["pool.ntp.org"];

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  programs = {
    firefox.enable = true;
  };

  my.allowedUnfree = with pkgs; [
    obsidian
  ];

  users = {
    mutableUsers = false;
  };

  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    obsidian

    hyprpaper

    hypridle
    brightnessctl
    tuigreet
    kanata
    kitty
    networkmanagerapplet
    nh
    pavucontrol
    swaynotificationcenter

    hyprpicker
    grim
    wl-clipboard

    # Screenshooting
    slurp
    swappy

    # Scanning tool
    simple-scan
  ];

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  fonts = {
    packages = with pkgs; [
      font-awesome
    ];
  };

  environment.variables = {
    NH_FLAKE = "/home/${username}/.dotfiles/nix";
  };

  # Obsidian still lives in `environment.systemPackages` (no
  # dedicated module yet) and wants native Wayland rendering.
  # Slack and Bitwarden flip the same toggle from their own
  # modules; the `true` declarations merge cleanly.
  my.needsOzoneWayland = true;

  # Services to start
  services = {
    tailscale = {
      enable = true;
    };
    openssh.enable = true;
    kanata = {
      enable = true;
      keyboards = {
        internalKeyboard = {
          extraDefCfg = ''
            process-unmapped-keys yes
            concurrent-tap-hold true
          '';
          config = builtins.readFile ../../config/kanata.kbd;
        };
      };
    };
  };

  # Bluetooth Support
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;

  # Optimization settings and garbage collection automation
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Route legacy nix CLI state (`~/.nix-defexpr`, `~/.nix-profile`,
      # `~/.nix-channels`) into $XDG_STATE_HOME/nix.
      use-xdg-base-directories = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Virtualization / Containers
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  console.keyMap = "us";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

  # See <https://wiki.nixos.org/wiki/Automatic_system_upgrades>
  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "--print-build-logs"
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };
}
