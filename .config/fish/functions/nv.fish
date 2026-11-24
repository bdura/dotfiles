function nv -d "Run the new neovim"
    nix run git+ssh://git@github.com/bdura/nvim -- $argv
end
