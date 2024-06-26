# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/dotfiles/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
 
typeset -a ANTIGEN_CHECK_FILES=(${ZDOTDIR:-~}/.zshrc)
 
source $ZDOTDIR/antigen.zsh
 
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-history-substring-search
antigen bundle zdharma-continuum/fast-syntax-highlighting
antigen bundle bossjones/boss-git-zsh-plugin
antigen bundle agkozak/zsh-z
antigen theme romkatv/powerlevel10k

antigen apply
 
# To customize prompt, run `p10k configure` or edit ~/dotfiles/.p10k.zsh.
[[ ! -f ~/dotfiles/.p10k.zsh ]] || source ~/dotfiles/.p10k.zsh

# Shell shortcuts to move cursor
bindkey "^[b" backward-word
bindkey "^[f" forward-word

# Shell shortcuts to move cursor in WSL
bindkey ";4D" backward-word
bindkey ";4C" forward-word

# kubectl
if [ $commands[kubectl] ]; then
  alias k=kubectl
  source <(kubectl completion zsh)
fi

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt inc_append_history
setopt share_history
