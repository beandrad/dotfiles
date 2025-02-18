#!/bin/bash

# sudo apt-get update && apt-get -y install zsh curl vim less
sudo apt-get -y install zsh curl vim less

curl -L git.io/antigen > $HOME/dotfiles/antigen.zsh

mkdir -p ~/.fonts
curl -L https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf --output ~/.fonts/'MesloLGS NF Regular.ttf'
curl -L https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf --output ~/.fonts/'MesloLGS NF Bold.ttf'
curl -L https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf --output ~/.fonts/'MesloLGS NF Italic.ttf'
curl -L https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf --output ~/.fonts/'MesloLGS NF Bold Italic.ttf'

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/dotfiles/themes/powerlevel10k

cp -rf  $HOME/dotfiles/.vimrc $HOME/.vimrc
echo "ZDOTDIR=$HOME/dotfiles" > $HOME/.zshenv
