{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    helix
    neovim-unwrapped
    opencode
    claude-code

    # Requirements for plugins
    python313
    clang
    rustup
    nixfmt
    lua
    luarocks

    unzip

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
    tomlq
    tree-sitter

    tlrc
  ];

  environment.variables = {
    EDITOR = "nvim";
    MANPAGER = "nvim --cmd 'set laststatus=0 ' +'set statuscolumn= nowrap laststatus=0' +Man\!";
  };
}
