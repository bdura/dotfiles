# Stop less from creating ~/.lesshst
set -gx LESSHISTFILE /dev/null

# Catppuccin Mocha colors for fzf, consistent with the shell theme.
# These are picked up automatically by `fzf --fish` key bindings.
set -gx FZF_DEFAULT_OPTS "\
  --height=40% --layout=reverse --border \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
