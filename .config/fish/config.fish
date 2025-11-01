if status is-interactive
    # Commands to run in interactive sessions can go here
    atuin init fish | sed 's/-k up/up/' | source
end

# Enable Vi keybindings
set -g fish_key_bindings fish_vi_key_bindings

# Overwrite fish_greeting with empty message
set fish_greeting
