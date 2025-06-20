{ unstable, ... }:
{
  environment.systemPackages = with unstable; [
    neovim-unwrapped
    nodejs-slim

    zoxide
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

  environment.variables.EDITOR = "nvim";
}
