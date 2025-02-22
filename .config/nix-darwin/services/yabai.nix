# # Yabai - a tiling window manager for macOS
#
# See the github page: <https://github.com/koekeishiya/yabai>
#
# A great resource: <https://www.josean.com/posts/yabai-setup>

{ ... }:
{
  #YABAI Window Manager
  services.yabai = {
    enable = true;
    # Yabai cannot be hot-reloaded, so it makes sense to configure it here.
    config = {
      external_bar = "off:40:0";
      menubar_opacity = 1.0;
      mouse_follows_focus = "on";
      focus_follows_mouse = "autofocus";
      display_arrangement_order = "default";
      window_origin_display = "default";
      window_placement = "second_child";
      window_insertion_point = "focused";
      window_zoom_persist = "on";
      window_shadow = "off";
      window_animation_duration = 0.0;
      window_animation_easing = "ease_out_circ";
      window_opacity_duration = 0.0;
      active_window_opacity = 1.0;
      normal_window_opacity = 0.90;
      window_opacity = "off";
      insert_feedback_color = "0xffd75f5f";
      split_ratio = 0.50;
      split_type = "auto";
      auto_balance = "off";
      top_padding = 6;
      bottom_padding = 6;
      left_padding = 6;
      right_padding = 6;
      window_gap = 6;
      layout = "bsp";
      mouse_modifier = "cmd";
      mouse_action1 = "move";
      mouse_action2 = "resize";
      mouse_drop_action = "swap";
    };
    extraConfig = ''
      yabai -m rule --add app='^System Settings$' manage=off
    '';
  };
}
