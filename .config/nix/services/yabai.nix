{ ... }:
{
  #YABAI Window Manager
  services.yabai = {
    enable = true;
    # config = {
    #   focus_follows_mouse = "autofocus";
    #   mouse_follows_focus = "on";
    #   window_placement = "second_child";
    #   window_opacity = "off";
    #   window_opacity_duration = 0.0;
    #   window_border = "off";
    #   window_border_placement = "inset";
    #   window_border_width = 2;
    #   window_border_radius = 100;
    #   active_window_border_topmost = "off";
    #   window_topmost = "on";
    #   window_shadow = "float";
    #   active_window_border_color = "0xff5c7e81";
    #   normal_window_border_color = "0xff505050";
    #   insert_window_border_color = "0xffd75f5f";
    #   active_window_opacity = "1.0";
    #   normal_window_opacity = "0.9";
    #   split_ratio = 0.50;
    #   auto_balance = "on";
    #   mouse_modifier = "cmd";
    #   mouse_action1 = "move";
    #   mouse_action2 = "resize";
    #   mouse_drop_action = "swap";
    #   layout = "bsp";
    #   top_padding = 6;
    #   bottom_padding = 6;
    #   left_padding = 6;
    #   right_padding = 6;
    #   window_gap = 6;
    # };
    # extraConfig = ''
    #   yabai -m rule --add app='^System Settings$' manage=off
    # '';
  };
}
