{ unstable, ... }:
{
  environment.systemPackages = with unstable; [
    zoxide
    neovim-unwrapped
    zellij
    atuin
    starship
    bat
    eza
    fd
    fzf
    htop
    jq
    ripgrep
    tmux
  ];
}
