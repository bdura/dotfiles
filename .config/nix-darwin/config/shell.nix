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
    fzf
    ripgrep
    starship
    zoxide
  ];

  programs = {
    zsh.enable = true;
  };
}
