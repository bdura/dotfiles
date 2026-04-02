type -q fzf && fzf --fish | source

type -q direnv && direnv hook fish | source

if type -q starship
    starship init fish | source
    enable_transience
end

type -q zoxide && zoxide init --cmd cd fish | source
