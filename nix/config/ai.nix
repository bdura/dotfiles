{
  pkgs,
  wrappers,
  ...
}: let
  claude = wrappers.lib.wrapPackage {
    pkgs = pkgs;
    package = pkgs.claude-code;
    binName = "claude";
    env = {
      CLAUDE_CONFIG_DIR = "$HOME/.config/claude";
    };
  };
  vibe = wrappers.lib.wrapPackage {
    pkgs = pkgs;
    package = pkgs.mistral-vibe;
    binName = "vibe";
    env = {
      VIBE_HOME = "$HOME/.config/vibe";
    };
  };
in {
  environment.systemPackages = [
    pkgs.opencode
    claude
    vibe

    # Tools
    pkgs.rtk
  ];
}
