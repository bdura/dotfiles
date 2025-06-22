function shell -d "Create a nix shell over nixpkgs"
    nix shell nixpkgs#$argv
end
