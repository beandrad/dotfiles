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
