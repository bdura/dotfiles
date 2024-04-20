if status is-interactive
    # Commands to run in interactive sessions can go here
end

function starship_transient_prompt_func
  starship module character
end

function starship_transient_rprompt_func
  starship module time
end

# Overwrite fish_greeting with empty message
set fish_greeting

zoxide init fish | source

starship init fish | source
enable_transience

