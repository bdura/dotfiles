# # Git configuration
#
# Git-related configuration. For now, some of the configuration is still
# managed by `stow` directly.

{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    git
    git-lfs
    serie
    lazygit
    pre-commit
  ];
}
