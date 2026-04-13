#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${HOME}/dotfiles"
ZSHRC_BOOTSTRAP_BEGIN="# >>> dotfiles-zsh-bootstrap >>>"
ZSHRC_BOOTSTRAP_END="# <<< dotfiles-zsh-bootstrap <<<"
LOCAL_PREFIX="${HOME}/.local"

export PATH="${LOCAL_PREFIX}/bin:${PATH}"

install_ncurses_from_source() {
	local ncurses_version="6.5"
	local build_dir="$1"

	echo "Building ncurses ${ncurses_version} from source into ${LOCAL_PREFIX}..."

	curl -fsSL "https://ftp.gnu.org/gnu/ncurses/ncurses-${ncurses_version}.tar.gz" \
		| tar xz -C "${build_dir}"

	(
		cd "${build_dir}/ncurses-${ncurses_version}"
		./configure --prefix="${LOCAL_PREFIX}" --with-shared --without-debug --enable-widec
		make -j"$(nproc 2>/dev/null || echo 1)"
		make install
	)

	echo "ncurses installed to ${LOCAL_PREFIX}"
}

install_zsh_from_source() {
	local zsh_version="5.9"
	local build_dir
	build_dir="$(mktemp -d)"
	trap "rm -rf '${build_dir}'" RETURN

	for cmd in gcc make; do
		if ! command -v "${cmd}" >/dev/null 2>&1; then
			echo "Error: '${cmd}' is required to build from source." >&2
			return 1
		fi
	done

	# Build ncurses locally if headers are not available
	if ! echo '#include <curses.h>' | gcc -E - >/dev/null 2>&1; then
		install_ncurses_from_source "${build_dir}"
		export CPPFLAGS="-I${LOCAL_PREFIX}/include -I${LOCAL_PREFIX}/include/ncursesw"
		export LDFLAGS="-L${LOCAL_PREFIX}/lib"
		export LD_LIBRARY_PATH="${LOCAL_PREFIX}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
	fi

	echo "Building zsh ${zsh_version} from source into ${LOCAL_PREFIX}..."

	curl -fsSL "https://sourceforge.net/projects/zsh/files/zsh/${zsh_version}/zsh-${zsh_version}.tar.xz/download" \
		| tar xJ -C "${build_dir}"

	(
		cd "${build_dir}/zsh-${zsh_version}"
		./configure --prefix="${LOCAL_PREFIX}"
		make -j"$(nproc 2>/dev/null || echo 1)"
		make install
	)

	echo "zsh installed to ${LOCAL_PREFIX}/bin/zsh"
}

if [[ "${OSTYPE}" == darwin* ]]; then
	FONT_DIR="${HOME}/Library/Fonts"
elif command -v apt-get >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
	sudo apt-get -y install zsh curl vim less
	FONT_DIR="${HOME}/.fonts"
else
	FONT_DIR="${HOME}/.fonts"
	if ! command -v zsh >/dev/null 2>&1; then
		install_zsh_from_source
	fi
	for cmd in curl vim less; do
		if ! command -v "${cmd}" >/dev/null 2>&1; then
			echo "Warning: '${cmd}' not found in PATH. Some features may not work." >&2
		fi
	done
fi

mkdir -p "${FONT_DIR}"

install_font() {
	local file_name="$1"
	local font_url="$2"
	curl -fsSL "${font_url}" --output "${FONT_DIR}/${file_name}"
}

if [[ "${OSTYPE}" == darwin* ]]; then
  install_font "MesloLGS NF Regular.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
  install_font "MesloLGS NF Bold.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
  install_font "MesloLGS NF Italic.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
  install_font "MesloLGS NF Bold Italic.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
fi

cp -rf "${DOTFILES_DIR}/.vimrc" "${HOME}/.vimrc"

cat > "${HOME}/.zshenv" <<EOF
export PATH="${LOCAL_PREFIX}/bin:\${PATH}"
ZDOTDIR=${DOTFILES_DIR}
EOF

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

zsh_path="$(command -v zsh 2>/dev/null || true)"
if [[ -n "${zsh_path}" ]]; then
	if ! chsh -s "${zsh_path}" 2>/dev/null; then
		echo ""
		echo "Could not change default shell (chsh failed or unavailable)."
		echo "Add this to your ~/.bashrc to auto-launch zsh:"
		echo "  if [ -x \"${zsh_path}\" ]; then exec \"${zsh_path}\" -l; fi"
	fi
fi
