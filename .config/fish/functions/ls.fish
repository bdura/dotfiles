function ls --wraps eza
    eza --long --group-directories-first --sort=Name --git --all $argv
end
