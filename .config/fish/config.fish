if status is-interactive
    # Commands to run in interactive sessions can go here
    atuin init fish | source
end

fish_add_path $HOME/.local/bin/
fish_add_path $HOME/.cargo/bin/

if test -e $HOME/.local/config.fish
    source $HOME/.local/config.fish
end

alias ls="eza -alh --git"
alias c=clear
alias gl=serie
alias lg=lazygit

# Overwrite fish_greeting with empty message
set fish_greeting

fzf --fish | source

direnv hook fish | source

starship init fish | source
enable_transience

zoxide init --cmd cd fish | source
