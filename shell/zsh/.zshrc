# ~/.zshrc — macOS Dev Environment

# ----------- ENVIRONMENT VARIABLES -----------
export EDITOR="vim"
export VISUAL="vim"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Secure environment loader
# Files are sourced in this order:
# 1. ~/.secure_env/exports.sh - Non-sensitive environment variables
# 2. ~/.secure_env/secrets.sh - Sensitive credentials (permissions 600)
[ -f "$HOME/.secure_env/exports.sh" ] && source "$HOME/.secure_env/exports.sh"
[ -f "$HOME/.secure_env/secrets.sh" ] && source "$HOME/.secure_env/secrets.sh"

# ----------- PATH MANAGEMENT -----------
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:$HOME/bin:$HOME/scripts:$PATH"

# ----------- ALIASES -----------
alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
alias c="clear"
alias grep="grep --color=auto"
alias reload="source ~/.zshrc"

# Git aliases
alias gst="git status"
alias gco="git checkout"
alias gl="git pull"
alias gp="git push"

# Terraform / Tofu aliases
alias terraform="tofu"
alias tf="tofu"

# ----------- PYTHON (UV: Universal Virtualenv Manager) -----------
if command -v uv >/dev/null 2>&1; then
  export UV_SYSTEM_PYTHON=1
fi

# ----------- NODE (NVM: Node Version Manager) -----------
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  source "$NVM_DIR/nvm.sh"
fi

# ----------- SSH AGENT SETUP -----------
if ! pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
  eval "$(ssh-agent -s)"
fi

DEFAULT_SSH_KEY="$HOME/.ssh/id_rsa"
if [ -f "$DEFAULT_SSH_KEY" ]; then
  ssh-add -q "$DEFAULT_SSH_KEY" 2>/dev/null
fi

# ----------- BREW BASH COMPLETION -----------
if [ -f /opt/homebrew/etc/profile.d/bash_completion.sh ]; then
  source /opt/homebrew/etc/profile.d/bash_completion.sh
fi

# ----------- PROMPT -----------
export PROMPT='%F{cyan}%n@%m %F{yellow}%~ %f$ '

# ----------- HISTORY SETTINGS -----------
HISTFILE=~/.zsh_history
HISTSIZE=25000
SAVEHIST=25000

setopt append_history
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt inc_append_history
setopt share_history

# ----------- FILE PERMISSIONS DEFAULT -----------
umask 022

# ----------- SYSTEM RESOURCE LIMITS -----------
# Raise the soft limit for open files (useful for dev work with many handles)
ulimit -n 65535

# ----------- LOAD CUSTOM EXTENSIONS -----------
[ -f ~/.custom_zsh ] && source ~/.custom_zsh
