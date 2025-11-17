{
  inputs,
  pkgs,
  host,
  username,
  options,
  ...
}:
let
  inherit (import ./variables.nix) keyboardLayout;
in
{
  imports = [
    ./hardware.nix
    ./disko.nix
    ./users.nix
    ../../config/direnv.nix
    ../../config/git.nix
    ../../config/dev.nix
    ../../modules/amd-drivers.nix
    ../../modules/nvidia-drivers.nix
    ../../modules/nvidia-prime-drivers.nix
    ../../modules/intel-drivers.nix
    ../../modules/vm-guest-services.nix
    ../../modules/local-hardware-clock.nix
  ];

  boot = {
    # Bootloader.
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      # Disable generation selection by default. Press any key to re-enable it.
      timeout = 0;
    };
    # Make /tmp a tmpfs
    tmp = {
      useTmpfs = true;
      cleanOnBoot = true;
      # The Tmpfs can use 30% of available RAM at most
      tmpfsSize = "30%";
    };
  };

  # swapfile on @swap subvolume
  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 16 * 1024; # 16 GiB
    }
  ];

  # Styling Options
  stylix = {
    enable = true;
    image = ../../config/wallpapers/mountainscapedark.jpg;
    # NOTE: this is from <https://github.com/tinted-theming/schemes/blob/spec-0.11/base16/tokyo-night-dark.yaml>
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

  # Extra Module Options
  drivers.amdgpu.enable = false;
  drivers.nvidia.enable = false;
  drivers.nvidia-prime = {
    enable = false;
    intelBusID = "";
    nvidiaBusID = "";
  };
  drivers.intel.enable = true;

  # vm.guest-services.enable = false;
  local.hardware-clock.enable = false;

  # Enable networking
  networking.networkmanager.enable = true;
  networking.hostName = host;
  networking.timeServers = options.networking.timeServers.default ++ [ "pool.ntp.org" ];

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  programs = {
    firefox.enable = true;
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };

  };

  nixpkgs.config.allowUnfree = true;

  users = {
    mutableUsers = false;
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = [
    # Add any missing dynamic libraries for unpackaged programs
    # here, NOT in environment.systemPackages
  ];

  console.font = "Lat2-Terminus16";

  environment.systemPackages = with pkgs; [
    slack
    obsidian

    bitwarden-desktop
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

    # Background
    swww
  ];

  fonts = {
    packages = with pkgs; [
      font-awesome
    ];
  };

  environment.variables = {
    NH_FLAKE = "/home/${username}/.dotfiles/nix";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_STATE_HOME = "$HOME/.local/state";
    SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";

    # Wayland apps (see <https://wiki.nixos.org/wiki/Slack>)
    NIXOS_OZONE_WL = "1";
  };

  # Services to start
  services = {
    tailscale = {
      enable = true;
    };
    greetd = {
      enable = true;
      settings = {
        default_session = {
          # Wayland Desktop Manager is installed only via home-manager!
          user = username;
          # .wayland-session is a script generated by home-manager, which links to the current wayland compositor(sway/hyprland or others).
          # with such a vendor-no-locking script, we can switch to another wayland compositor without modifying greetd's config here.
          # command = "$HOME/.wayland-session"; # start a wayland session directly without a login manager
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland"; # start Hyprland with a TUI login manager
        };
      };
    };
    openssh.enable = true;
    # pipewire = {
    #   enable = true;
    #   alsa.enable = true;
    #   alsa.support32Bit = true;
    #   pulse.enable = true;
    # };
    kanata = {
      enable = true;
      keyboards = {
        internalKeyboard = {
          extraDefCfg = "process-unmapped-keys yes";
          config = builtins.readFile ../../config/kanata.kbd;
        };
      };
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    printing = {
      enable = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
      ];
    };
  };

  # Bluetooth Support
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;

  security.pam.services.swaylock = {
    text = ''
      auth include login
    '';
  };

  # Optimization settings and garbage collection automation
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
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

  # # OpenGL
  # hardware.graphics = {
  #   enable = true;
  # };

  console.keyMap = "${keyboardLayout}";

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

  # TODO: fix this part
  # # Enable screen-sharing
  # xdg.portal = {
  #   enable = true;
  #   extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
  # };
}
