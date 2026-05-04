# # Neovim
#
# Every dependency needed to run Neovim.
#
# We use the unwrapped version, because configuring Neovim is out-of-scope
# and handled through plain dotfiles.
{
  pkgs,
  wrappers,
  ...
}: let
  nvim = wrappers.lib.wrapPackage {
    pkgs = pkgs;
    package = pkgs.neovim-unwrapped;
    binName = "nvim";
    runtimeInputs = with pkgs; [
      nixd
      rumdl

      # Fuzzy-finding
      fzf
      ripgrep
      fd

      # Git integration
      git
      git-lfs
      lazygit

      # Various build tools
      lua
      luarocks
      tree-sitter

      # Formatters and render tools used by plugins
      nixfmt
      alejandra
      imagemagick # Image conversion
      ghostscript # PDF files
      tectonic # Render LaTeX expressions
      mermaid-cli # Render mermaid diagrams
      # latexmk
      # bibtex
      biber
    ];
  };
in {
  environment.systemPackages = [
    nvim
  ];

  environment.variables = let
    bin = "${nvim}/bin/nvim";
  in {
    EDITOR = bin;
    MANPAGER = "${bin} --cmd 'set laststatus=0 ' +'set statuscolumn= nowrap laststatus=0' +Man\!";
  };
}
