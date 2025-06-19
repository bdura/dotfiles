# # Shell configuration
#
# Only installs required packages. The actual configuration happens
# in a `stow`-managed dotfile, for faster iteration.

{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # Command-line fuzzy-finder: <https://github.com/junegunn/fzf>
    fzf
    # Faster grep: <https://github.com/BurntSushi/ripgrep>
    ripgrep
    # Cross-shell prompt: <https://starship.rs/>
    starship
    # Filesystem explorer: <https://yazi-rs.github.io/>
    yazi
    # Better cd: <https://github.com/ajeetdsouza/zoxide>
    zoxide
    # A simple and fast alternative to find: <https://github.com/sharkdp/fd>
    fd
    # Better shell history: <https://atuin.sh/>
    atuin
  ];

  programs = {
    fish.enable = true;
  };

  environment.variables = {
    SHELL = "fish";
  };

  # Note: on macOS at least, you'll need to run the following command:
  # `chsh -s $(which fish)`
  # to make fish your login shell
  environment.shells = [ pkgs.fish ];
}
