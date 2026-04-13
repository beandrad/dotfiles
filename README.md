# dotfiles

## Setup

Run:

```bash
./setup-shell.sh
```

In devcontainers that pre-create `~/.zshrc`, running the setup script appends an idempotent bootstrap block so `~/dotfiles/.zshrc` is still sourced.

## WSL / no-sudo environments

When `sudo` is unavailable the setup script automatically:

1. Builds **ncurses** and **zsh from source** into `~/.local` (requires `gcc`, `make`, and `curl`).
2. Warns about any other missing tools (`vim`, `less`).
3. Adds `~/.local/bin` to `PATH` via `~/.zshenv`.
4. Attempts `chsh`; if that fails it prints a one-liner to add to `~/.bashrc` so zsh launches automatically.

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

By default the worktree is created as a **sibling** of the repo:

```
~/projects/
├── my-repo/                  ← original repo
└── my-repo-feat-my-change/   ← worktree (created automatically)
```

### Devcontainer usage

The worktree uses relative git paths, so both the repo and the worktree must be
mounted into the devcontainer. Mount the **parent directory** that contains both
by adding a workspace mount to `.devcontainer/devcontainer.json`:

```jsonc
{
  "workspaceMount": "source=${localWorkspaceFolder}/..,target=/workspaces,type=bind",
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}"
}
```

This mounts the parent of your repo as `/workspaces`, giving the container
access to both directories while preserving the relative paths between them.
