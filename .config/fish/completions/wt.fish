function __wt_branches
    git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null
    git for-each-ref --format='%(refname:lstrip=3)' refs/remotes/origin 2>/dev/null | string match -v HEAD
end

# Branches checked out in a worktree other than the main checkout.
function __wt_linked_branches
    set -l main 1
    git worktree list --porcelain 2>/dev/null | while read -l key value
        switch $key
            case ''
                set main 0
            case branch
                test $main = 0; and string replace refs/heads/ '' -- $value
        end
    end
end

function __wt_args -a n
    test (count (commandline -xpc)) -eq $n
end

complete -c wt -f
complete -c wt -s h -l help -d "Show usage"
complete -c wt -n "__wt_args 1" -a rm -d "Remove a worktree"
complete -c wt -n "__wt_args 1" -a "(__wt_branches | sort -u)"
complete -c wt -n "__wt_args 2; and not __fish_seen_subcommand_from rm" -a "(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes 2>/dev/null)" -d Base
complete -c wt -n "__fish_seen_subcommand_from rm" -s f -l force -d "Remove even if dirty"
complete -c wt -n "__fish_seen_subcommand_from rm" -a "(__wt_linked_branches)" -d Worktree
