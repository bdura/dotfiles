function shell -d "Build with nom, then open a nix shell (defaults to nixpkgs)"
    # Usage: shell [installable...] [-- command args...]
    #   shell ripgrep fd          -> nixpkgs#ripgrep nixpkgs#fd
    #   shell .#foo               -> local flake attribute
    #   shell jq -- jq --version  -> run a command instead of a shell
    set -l refs
    set -l cmd
    if set -l i (contains -i -- -- $argv)
        set refs $argv[1..$i]
        set -e refs[-1]
        set cmd $argv[(math $i + 1)..-1]
    else
        set refs $argv
    end
    set refs (__nix_ref $refs)
    set -q refs[1]; or set refs .

    __nix_build $refs; or return
    if set -q cmd[1]
        nix shell $refs --command $cmd
    else
        nix shell $refs
    end
end
