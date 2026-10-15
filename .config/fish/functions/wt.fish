function wt -d "Create a git worktree for a branch and cd into it"
    switch "$argv[1]"
        case rm
            __wt_rm $argv[2..]
            return
        case -h --help
            echo "usage: wt <branch> [base]"
            echo "       wt rm [-f] [branch]"
            return
        case --
            set -e argv[1]
    end

    set -l branch $argv[1]
    set -l base $argv[2]
    if test -z "$branch"
        echo "usage: wt <branch> [base]" >&2
        return 2
    end
    git check-ref-format --branch $branch >/dev/null; or return

    set -l root (__wt_root); or return
    set -l target $root/.worktrees/(string replace -a / - -- $branch)

    set -l existing (__wt_find $branch)
    if test "$existing" = "$target"
        echo "wt: $branch already checked out here" >&2
        cd $target
        return
    else if test -n "$existing"
        echo "wt: $branch is already checked out at $existing" >&2
        return 1
    end

    if test -e $target
        if contains -- $target (__wt_list)
            set -l other (git -C $target symbolic-ref --short -q HEAD; or echo "a detached HEAD")
            echo "wt: $target already holds $other" >&2
        else
            echo "wt: $target exists but is not a registered worktree" >&2
            echo "    run `git worktree prune` or remove it" >&2
        end
        return 1
    end

    if git -C $root show-ref --verify -q refs/heads/$branch
        test -n "$base"; and echo "wt: $branch already exists, ignoring base $base" >&2
        git -C $root worktree add $target $branch
    else if git -C $root show-ref --verify -q refs/remotes/origin/$branch
        test -n "$base"; and echo "wt: tracking origin/$branch, ignoring base $base" >&2
        git -C $root worktree add --track -b $branch $target origin/$branch
    else
        if test -z "$base"
            set base (git -C $root symbolic-ref -q --short refs/remotes/origin/HEAD; or echo main)
        end
        git -C $root worktree add --no-track -b $branch $target $base
    end
    or return

    # Ignored files are not checked out: share the ones that hold local configuration.
    for file in $root/.env* $root/shell.nix $root/CLAUDE.md $root/AGENTS.md
        set -l dest $target/(path basename $file)
        if test -e $file; and not test -e $dest; and not test -L $dest
            ln -s $file $dest
        end
    end

    cd $target
    if test -e .envrc; and command -q direnv
        direnv allow .
    end
end

function __wt_rm
    argparse f/force -- $argv; or return
    set -l root (__wt_root); or return

    set -l target
    if set -q argv[1]
        set target (__wt_find $argv[1])
        if test -z "$target"
            echo "wt: no worktree for $argv[1]" >&2
            return 1
        end
    else
        set target (git rev-parse --show-toplevel); or return
    end
    if test "$target" = "$root"
        echo "wt: refusing to remove the main checkout" >&2
        return 1
    end

    set -l branch (git -C $target symbolic-ref --short -q HEAD)
    set -l pwd (path resolve $PWD)
    set -l inside (test "$pwd" = "$target"; or string match -q -- "$target/*" $pwd; and echo 1)

    test -n "$inside"; and cd $root
    if not git -C $root worktree remove (set -q _flag_force; and echo --force) $target
        test -n "$inside"; and cd $pwd
        return 1
    end

    if test -n "$branch"; and not git -C $root branch -d $branch 2>/dev/null
        echo "wt: kept unmerged branch $branch (`git branch -D $branch` to delete it)" >&2
    end
end

# Root of the main checkout, shared by every worktree.
function __wt_root
    set -l common (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if test -z "$common"
        echo "wt: not in a git repository" >&2
        return 1
    end
    if test "$(git -C $common config --bool core.bare)" = true
        echo "wt: bare repositories are not supported" >&2
        return 1
    end
    path dirname $common
end

function __wt_list
    git worktree list --porcelain | string replace -rf '^worktree ' ''
end

# Path of the worktree where the branch is checked out, if any.
function __wt_find -a branch
    set -l path
    git worktree list --porcelain | while read -l key value
        switch $key
            case worktree
                set path $value
            case branch
                if test "$value" = refs/heads/$branch
                    echo $path
                    return
                end
        end
    end
end
