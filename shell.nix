{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    stow
    nixd
    nixfmt
    kdlfmt
    rumdl
    stylua
    alejandra
    kdlfmt
    lua-language-server
    rustup
  ];
}
