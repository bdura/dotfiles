{
  pkgs,
  username,
  host,
  ...
}:
let
  inherit (import ./variables.nix) gitUsername gitEmail;
in
{
  # Home Manager Settings
  home.username = "${username}";
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "23.11";

  # Import Program Configurations
  imports = [
    ../../config/emoji.nix
    ../../config/fastfetch
    # ../../config/neovim.nix
    ../../config/hyprland.nix
    ../../config/rofi/rofi.nix
    ../../config/rofi/config-emoji.nix
    ../../config/rofi/config-long.nix
    ../../config/swaync.nix
    ../../config/waybar.nix
    ../../config/wlogout.nix
    ../../config/fastfetch
  ];

  # Place Files Inside Home Directory
  home.file."Pictures/Wallpapers" = {
    source = ../../config/wallpapers;
    recursive = true;
  };
  home.file.".config/wlogout/icons" = {
    source = ../../config/wlogout;
    recursive = true;
  };
  home.file.".face.icon".source = ../../config/face.jpg;
  home.file.".config/face.jpg".source = ../../config/face.jpg;
  home.file.".config/swappy/config".text = ''
    [Default]
    save_dir=/home/${username}/Pictures/Screenshots
    save_filename_format=swappy-%Y%m%d-%H%M%S.png
    show_panel=false
    line_size=5
    text_size=20
    text_font=Ubuntu
    paint_mode=brush
    early_exit=true
    fill_shape=false
  '';

  # Install & Configure Git
  programs.git = {
    enable = true;
    userName = "${gitUsername}";
    userEmail = "${gitEmail}";
  };

  # Create XDG Dirs
  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };

  # Styling Options
  stylix.targets.waybar.enable = false;
  stylix.targets.rofi.enable = false;
  stylix.targets.hyprland.enable = false;
  gtk = {
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };
  qt = {
    enable = true;
    style.name = "adwaita-dark";
    platformTheme.name = "gtk3";
  };

  # Scripts
  home.packages = [
    (import ../../scripts/emopicker9000.nix { inherit pkgs; })
    (import ../../scripts/task-waybar.nix { inherit pkgs; })
    (import ../../scripts/squirtle.nix { inherit pkgs; })
    (import ../../scripts/nvidia-offload.nix { inherit pkgs; })
    (import ../../scripts/wallsetter.nix {
      inherit pkgs;
      inherit username;
    })
    (import ../../scripts/web-search.nix { inherit pkgs; })
    (import ../../scripts/rofi-launcher.nix { inherit pkgs; })
    (import ../../scripts/screenshootin.nix { inherit pkgs; })
    (import ../../scripts/list-hypr-bindings.nix {
      inherit pkgs;
      inherit host;
    })
  ];

  services = {
    hypridle = {
      enable = true;
      settings = {
        general = {
          after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
          lock_cmd = "hyprlock";
        };
        listener = [
          {
            timeout = 60;
            on-timeout = "brightnessctl -s set 20"; # set monitor backlight to minimum, avoid 0 on OLED monitor.
            on-resume = "brightnessctl -r"; # monitor backlight restore.
          }
          {
            timeout = 120;
            on-timeout = "hyprlock";
          }
          {
            timeout = 180;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = 600;
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  };

  programs = {
    gh.enable = true;
    btop = {
      enable = true;
      settings = {
        vim_keys = true;
      };
    };
    # kitty = {
    #   enable = true;
    #   package = pkgs.kitty;
    #   settings = {
    #     scrollback_lines = 2000;
    #     wheel_scroll_min_lines = 1;
    #     window_padding_width = 4;
    #     confirm_os_window_close = 0;
    #   };
    #   extraConfig = ''
    #     tab_bar_style fade
    #     tab_fade 1
    #     active_tab_font_style   bold
    #     inactive_tab_font_style bold
    #   '';
    # };
    # starship = {
    #   enable = true;
    #   package = pkgs.starship;
    # };
    home-manager.enable = true;
    hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          grace = 3;
          hide_cursor = true;
          ignore_empty_input = true;
        };
        background = [
          {
            path = "";
            color = "rgb(1e1e2e)";
          }
        ];
        label = [
          {
            monitor = "";
            text = "$TIME";
            color = "rgb(cdd6f4)";
            font_size = 90;
            font_family = "JetBrainsMono Nerd Font";
            position = "-30, 0";
            halign = "right";
            valign = "top";
          }
          {
            monitor = "";
            text = ''cmd[update:43200000] date +"%A, %d %B %Y"'';
            color = "rgb(cdd6f4)";
            font_size = 25;
            font_family = "JetBrainsMono Nerd Font";
            position = "-30, -150";
            halign = "right";
            valign = "top";
          }
        ];
        input-field = [
          {
            size = "300, 50";
            position = "0, 0";
            monitor = "";
            dots_center = true;
            fade_on_empty = false;
            font_color = "rgb(CFE6F4)";
            inner_color = "rgb(657DC2)";
            outer_color = "rgb(0D0E15)";
            outline_thickness = 5;
            placeholder_text = "Password...";
            shadow_passes = 2;
          }
        ];
      };
    };
  };
}
