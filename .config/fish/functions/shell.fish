function shell -d "Create a nix shell over nixpkgs"
    nix shell (string replace -r '^' 'nixpkgs#' -- $argv)
end
