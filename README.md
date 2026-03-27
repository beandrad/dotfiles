# dotfiles

## Setup

Run:

```bash
./setup-shell.sh
```

In devcontainers that pre-create `~/.zshrc`, running the setup script appends an idempotent bootstrap block so `~/dotfiles/.zshrc` is still sourced.

## macOS notes

- `setup-shell.sh` installs Meslo Nerd Font files into `~/Library/Fonts`.
- In iTerm2, set your profile font to **MesloLGS NF** so Powerlevel10k symbols render correctly.
