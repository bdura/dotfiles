function ls --wraps ls
    eza --long --group-directories-first --sort=Name --git --all $argv
end
