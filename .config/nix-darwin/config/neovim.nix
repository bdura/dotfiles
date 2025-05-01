{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    neovim

    fzf
    git
    git-lfs
    lazygit
    nixfmt-rfc-style
    pre-commit
    ripgrep
    fd # Faster find

    cmake
    lua
    luarocks
    imagemagick # Image conversion
    ghostscript # PDF files
    tectonic # Render LaTeX expressions
    mermaid-cli # Render mermaid diagrams
    # latexmk
    # bibtex
    biber
    skhd
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
