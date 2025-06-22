# Shamelessly ripped from: <https://github.com/clo4/nix-dotfiles/blob/b4b72ec2c357d5cead2e05f67ae2e6d1c4901f60/config/fish/functions/clean-store.fish>
function clean-store -d "Clean & optimise nix store"
    announce nix store gc --verbose
    echo
    announce nix store optimise --verbose
end
