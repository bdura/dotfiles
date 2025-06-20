if status is-interactive
    # Commands to run in interactive sessions can go here
    atuin init fish | source
end

fish_add_path $HOME/.local/bin/
fish_add_path $HOME/.cargo/bin/

if test -e $HOME/.local/config.fish
    source $HOME/.local/config.fish
end

# Overwrite fish_greeting with empty message
set fish_greeting
