#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${HOME}/dotfiles"
ZSHRC_BOOTSTRAP_BEGIN="# >>> dotfiles-zsh-bootstrap >>>"
ZSHRC_BOOTSTRAP_END="# <<< dotfiles-zsh-bootstrap <<<"

if [[ "${OSTYPE}" == darwin* ]]; then
	FONT_DIR="${HOME}/Library/Fonts"
elif command -v apt-get >/dev/null 2>&1; then
	sudo apt-get -y install zsh curl vim less
	FONT_DIR="${HOME}/.fonts"
else
	FONT_DIR="${HOME}/.fonts"
fi

mkdir -p "${FONT_DIR}"

install_font() {
	local file_name="$1"
	local font_url="$2"
	curl -fsSL "${font_url}" --output "${FONT_DIR}/${file_name}"
}

install_font "MesloLGS NF Regular.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
install_font "MesloLGS NF Bold.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
install_font "MesloLGS NF Italic.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
install_font "MesloLGS NF Bold Italic.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"

cp -rf "${DOTFILES_DIR}/.vimrc" "${HOME}/.vimrc"
echo "ZDOTDIR=${DOTFILES_DIR}" > "${HOME}/.zshenv"

zshrc_path="${HOME}/.zshrc"
touch "${zshrc_path}"

if ! grep -Fq "${ZSHRC_BOOTSTRAP_BEGIN}" "${zshrc_path}"; then
	{
		echo ""
		echo "${ZSHRC_BOOTSTRAP_BEGIN}"
		echo "[[ -f \"${DOTFILES_DIR}/.zshrc\" ]] && source \"${DOTFILES_DIR}/.zshrc\""
		echo "${ZSHRC_BOOTSTRAP_END}"
	} >> "${zshrc_path}"
fi

if [[ "${OSTYPE}" == darwin* ]]; then
	echo "Fonts installed to ${FONT_DIR}."
	echo "In iTerm2, set your profile font to MesloLGS NF for proper symbols/icons."
fi
