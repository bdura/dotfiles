function run -d "Build with nom, then nix run (defaults to nixpkgs)"
    # Usage: run [installable] [args...]
    #   run hello            -> nixpkgs#hello
    #   run .                -> default package of the local flake
    #   run .#foo -- --help  -> local flake attribute
    #   run github:o/r#pkg   -> any flake reference
    set -l ref .
    if set -q argv[1]; and test "$argv[1]" != --
        set ref $argv[1]
        set -e argv[1]
    end
    test "$argv[1]" = --; and set -e argv[1]

    set ref (__nix_ref $ref)

    __nix_build $ref; or return

    nix run $ref -- $argv
end
