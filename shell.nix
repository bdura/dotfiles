{pkgs ? import <nixpkgs> {}}: let
  # Symlink farm exposing pi's bundled runtime deps as a `node_modules/`
  # directory, so typescript-language-server can resolve
  # `@earendil-works/pi-coding-agent` (and its own deps: pi-ai, pi-tui,
  # typebox, @types/node, ...) when editing `.config/pi/extensions/*.ts`.
  #
  # `@earendil-works/pi-coding-agent` *is* pi-monorepo itself, so it isn't
  # present inside pi-monorepo's own node_modules/@earendil-works/ (a
  # package isn't its own dependency) - that one entry is added by hand,
  # everything else is symlinked in bulk straight from the store.
  piLib = "${pkgs.pi-coding-agent}/lib/node_modules/pi-monorepo";
  piNodeModules =
    pkgs.runCommand "pi-agent-node-modules" {}
    ''
      mkdir -p "$out/@earendil-works"
      for entry in ${piLib}/node_modules/*; do
        name="$(basename "$entry")"
        [ "$name" = "@earendil-works" ] && continue
        ln -s "$entry" "$out/$name"
      done
      ln -s ${piLib} "$out/@earendil-works/pi-coding-agent"
      ln -s ${piLib}/node_modules/@earendil-works/pi-ai "$out/@earendil-works/pi-ai"
      ln -s ${piLib}/node_modules/@earendil-works/pi-tui "$out/@earendil-works/pi-tui"
    '';
in
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

      rustc
      cargo
      gcc
      binutils
      pkg-config

      typescript-language-server
    ];

    shellHook = ''
      ln -sfn ${piNodeModules} "$PWD/.config/pi/node_modules"
    '';
  }
