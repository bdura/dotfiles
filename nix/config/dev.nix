{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    helix

    unzip

    zoxide
    zellij
    atuin
    starship
    bat
    eza
    fd
    fzf
    btop
    jq
    ripgrep
    tmux
    tomlq
    tree-sitter

    tlrc
  ];
}
