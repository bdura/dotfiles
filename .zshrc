# Define the directory for zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit if not present
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light softmoth/zsh-vim-mode
zinit light Aloxaf/fzf-tab

# Add snippets
zinit snippet OMZP::git

# Load completions
autoload -U compinit && compinit

zinit cdreplay -q

# Keybindings
# bindkey -v
bindkey '^y' autosuggest-accept
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Catppuccin for fzf
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#313244,label:#CDD6F4"

# Some useful variables
export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR="nvim"
export SHELL=$(which zsh)

# Aliases
alias ls="eza -alh --git"
alias c="clear"
alias gl=serie
alias zshconfig="$EDITOR $HOME/.zshrc"

# Paths
export PATH="$PATH:$HOME/.local/bin"

# Sourcing
source "$HOME/.ghcup/env"

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Enable fzf
eval "$(fzf --zsh)"

# Enable zoxide
eval "$(zoxide init --cmd cd zsh)"

# Enable starship
eval "$(starship init zsh)"

# Enable direnv
eval "$(direnv hook zsh)"
