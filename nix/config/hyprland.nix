{
  lib,
  pkgs,
  config,
  ...
}: let
  # Screenshooting utility
  screenshooting = pkgs.writeShellApplication {
    name = "screenshootin";
    runtimeInputs = with pkgs; [grim slurp swappy];
    text = ''
      grim -g "$(slurp)" - | swappy -f -
    '';
  };

  # Screen-recording toggle. First press prompts for a region and
  # starts wf-recorder in the background; second press sends SIGINT
  # so wf-recorder flushes the mp4 cleanly before exiting.
  videoshooting = pkgs.writeShellApplication {
    name = "videoshootin";
    runtimeInputs = with pkgs; [wf-recorder slurp libnotify procps coreutils];
    text = ''
      if pgrep -x wf-recorder > /dev/null; then
        pkill -INT -x wf-recorder
        notify-send "Recording stopped"
      else
        geometry=$(slurp) || exit 1
        output_dir="$HOME/Videos"
        mkdir -p "$output_dir"
        output="$output_dir/recording-$(date +%Y%m%d-%H%M%S).mp4"
        wf-recorder -g "$geometry" -f "$output" &
        notify-send "Recording started" "$output"
      fi
    '';
  };
in {
  home.packages = [
    screenshooting
    videoshooting
    pkgs.hyprpicker
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;
    extraConfig = let
      modifier = "SUPER";
    in
      lib.concatStrings [
        # hyprlang
        ''
          env = XDG_CURRENT_DESKTOP, Hyprland
          env = XDG_SESSION_TYPE, wayland
          env = XDG_SESSION_DESKTOP, Hyprland
          env = GDK_BACKEND, wayland, x11
          env = QT_QPA_PLATFORM=wayland;xcb
          env = QT_WAYLAND_DISABLE_WINDOWDECORATION, 1
          env = QT_AUTO_SCREEN_SCALE_FACTOR, 1
          exec-once = hyprpaper
          exec-once = hypridle
          exec-once = dbus-update-activation-environment --systemd --all
          exec-once = systemctl --user import-environment QT_QPA_PLATFORMTHEME WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
          exec-once = killall -q waybar;sleep .5 && waybar
          exec-once = killall -q swaync;sleep .5 && swaync
          exec-once = nm-applet --indicator
          exec-once = lxqt-policykit-agent


          $dotblocksLGScreen = LG Electronics LG HDR 4K 0x00025CD8
          $homeScreen = Samsung Electric Company LS27D80xU HNAX400122

          # See https://wiki.hyprland.org/Configuring/Monitors/
          monitor = eDP-1,preferred,auto,1
          monitor = desc:$dotblocksLGScreen,preferred,auto-up,1
          monitor = desc:$homeScreen,preferred,auto-left,1
          # Uncomment next line to mirror eDP-1
          monitor = ,preferred,auto-up,1
          # monitor = , preferred, auto, 1, mirror, eDP-1


          general {
            gaps_in = 6
            gaps_out = 8
            border_size = 2
            layout = dwindle
            resize_on_border = true
            col.active_border = rgb(${config.stylix.base16Scheme.base08}) rgb(${config.stylix.base16Scheme.base0C}) 45deg
            col.inactive_border = rgb(${config.stylix.base16Scheme.base01})
          }
          input {
            kb_layout = us
            kb_variant = mac
            # kb_options = grp:alt_shift_toggle
            # kb_options = caps:super
            follow_mouse = 1
            touchpad {
              natural_scroll = true
              disable_while_typing = true
              scroll_factor = 0.8
            }
            sensitivity = 0.5 # -1.0 - 1.0, 0 means no modification.
            accel_profile = flat
          }
          windowrule = border_size 0, match:class ^(wofi)$
          windowrule = center on, match:class ^(wofi)$
          windowrule = center on, match:class ^(steam)$
          windowrule = float on, match:class nm-connection-editor|blueman-manager
          windowrule = float on, match:class swayimg|vlc|Viewnior|pavucontrol
          windowrule = float on, match:class ^Bitwarden$
          windowrule = float on, match:class nwg-look|qt5ct|mpv
          gesture = 3, horizontal, workspace
          misc {
            initial_workspace_tracking = 0
            mouse_move_enables_dpms = true
            key_press_enables_dpms = false
          }
          animations {
            enabled = yes
            bezier = wind, 0.05, 0.9, 0.1, 1.05
            bezier = winIn, 0.1, 1.1, 0.1, 1.1
            bezier = winOut, 0.3, -0.3, 0, 1
            bezier = liner, 1, 1, 1, 1
            animation = windows, 1, 6, wind, slide
            animation = windowsIn, 1, 6, winIn, slide
            animation = windowsOut, 1, 5, winOut, slide
            animation = windowsMove, 1, 5, wind, slide
            animation = border, 1, 1, liner
            animation = fade, 1, 10, default
            animation = workspaces, 1, 5, wind
          }
          decoration {
            rounding = 10
            blur {
                enabled = true
                size = 5
                passes = 3
                new_optimizations = on
                ignore_opacity = off
            }
          }
          plugin {
            hyprtrails {
            }
          }
          dwindle {
            # pseudotile = true
            preserve_split = true
          }
          bind = ${modifier},Return,exec,kitty
          bind = ${modifier}SHIFT,Return,exec,firefox
          bind = ${modifier},SPACE,exec,rofi-launcher
          bind = ${modifier}SHIFT,N,exec,swaync-client -rs
          bind = ${modifier},W,killactive,
          bind = ${modifier},S,exec,screenshootin
          bind = ${modifier}SHIFT,S,exec,videoshootin
          bind = ${modifier},C,exec,hyprpicker -a
          bind = ${modifier},T,exec,thunar
          bind = ${modifier},F,fullscreen,
          bind = ${modifier}SHIFT,F,togglefloating,
          bind = ${modifier}SHIFT,left,movewindow,l
          bind = ${modifier}SHIFT,right,movewindow,r
          bind = ${modifier}SHIFT,up,movewindow,u
          bind = ${modifier}SHIFT,down,movewindow,d
          bind = ${modifier}SHIFT,h,movewindow,l
          bind = ${modifier}SHIFT,l,movewindow,r
          bind = ${modifier}SHIFT,k,movewindow,u
          bind = ${modifier}SHIFT,j,movewindow,d
          bind = ${modifier}ALT,h,resizeactive,-30 0
          bind = ${modifier}ALT,l,resizeactive,30 0
          bind = ${modifier}ALT,k,resizeactive,0 -30
          bind = ${modifier}ALT,j,resizeactive,0 30
          bind = ${modifier},left,movefocus,l
          bind = ${modifier},right,movefocus,r
          bind = ${modifier},up,movefocus,u
          bind = ${modifier},down,movefocus,d
          bind = ${modifier},h,movefocus,l
          bind = ${modifier},l,movefocus,r
          bind = ${modifier},k,movefocus,u
          bind = ${modifier},j,movefocus,d
          bind = ${modifier},1,workspace,1
          bind = ${modifier},2,workspace,2
          bind = ${modifier},3,workspace,3
          bind = ${modifier},4,workspace,4
          bind = ${modifier},5,workspace,5
          bind = ${modifier},6,workspace,6
          bind = ${modifier},7,workspace,7
          bind = ${modifier},8,workspace,8
          bind = ${modifier},9,workspace,9
          bind = ${modifier},0,workspace,10
          bind = ${modifier}SHIFT,1,movetoworkspace,1
          bind = ${modifier}SHIFT,2,movetoworkspace,2
          bind = ${modifier}SHIFT,3,movetoworkspace,3
          bind = ${modifier}SHIFT,4,movetoworkspace,4
          bind = ${modifier}SHIFT,5,movetoworkspace,5
          bind = ${modifier}SHIFT,6,movetoworkspace,6
          bind = ${modifier}SHIFT,7,movetoworkspace,7
          bind = ${modifier}SHIFT,8,movetoworkspace,8
          bind = ${modifier}SHIFT,9,movetoworkspace,9
          bind = ${modifier}SHIFT,0,movetoworkspace,10
          bind = ${modifier}CONTROL,right,workspace,e+1
          bind = ${modifier}CONTROL,left,workspace,e-1
          bind = ,XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
          bind = ,XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
          binde = ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
          bind = ,XF86AudioPlay, exec, playerctl play-pause
          bind = ,XF86AudioPause, exec, playerctl play-pause
          bind = ,XF86AudioNext, exec, playerctl next
          bind = ,XF86AudioPrev, exec, playerctl previous
          bind = ,XF86MonBrightnessDown,exec,brightnessctl set 5%-
          bind = ,XF86MonBrightnessUp,exec,brightnessctl set +5%
          bind = ${modifier}, ESCAPE, exec, hyprlock
        ''
      ];
  };
}
