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

## Copilot worktree wrapper

Run Copilot in a disposable worktree and have any resulting changes committed to
the branch automatically. If the repo root has a `.env`, it is copied into the
new worktree before Copilot starts:

```bash
~/dotfiles/copilot-worktree.sh feat/my-change -- --prompt "implement the change"
```

After reloading your shell, you can also use:

```bash
copilotwt feat/my-change -- --prompt "implement the change"
```
