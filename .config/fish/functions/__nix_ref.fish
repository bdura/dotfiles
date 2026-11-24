function __nix_ref -d "Qualify bare names as nixpkgs attributes, pass flake refs through"
    # Anything that is not a flake ref (no `#`, not a path, no `scheme:`) is a nixpkgs attribute.
    for ref in $argv
        if string match -qr '#|^[./]|^[a-z+]+:' -- $ref
            echo $ref
        else
            echo "nixpkgs#$ref"
        end
    end
end
