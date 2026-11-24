function __nix_build -d "Build installables without linking, with nom when available"
    if command -q nom
        nom build --no-link $argv
    else
        nix build --no-link $argv
    end
end
