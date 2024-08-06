if status is-interactive
    # Commands to run in interactive sessions can go here
end

function starship_transient_prompt_func
  starship module character
end

function starship_transient_rprompt_func
  starship module time
end

fish_add_path /opt/homebrew/bin/
fish_add_path $HOME/.local/bin/

set -x POETRY_CONFIG_DIR $HOME/.config/poetry

if test -e $HOME/.local/config.fish
  source $HOME/.local/config.fish
end

# Overwrite fish_greeting with empty message
set fish_greeting

zoxide init fish | source

starship init fish | source
enable_transience
