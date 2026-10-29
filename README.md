# dotfiles-watcher

Auto-sync your dotfiles bare repo on file change, with AI-generated commit messages.

Watches all files tracked by a bare git repo at `~/.cfg/` using [`entr`](https://eradman.com/entrproject/). On any change, stages, commits (via Gemini), and pushes.

## Dependencies

- `git`
- [`entr`](https://eradman.com/entrproject/) — `paru -S entr`
- `gemini` (Antigravity CLI) — for AI commit messages; falls back to timestamp

## Installation

```bash
git clone https://github.com/Vikyek/dotfiles-watcher.git
cd dotfiles-watcher
./install.sh
```

This will:
1. Copy `dotfiles-watcher` and `dotfiles-sync` to `/usr/local/bin/`
2. Install the systemd user service to `~/.config/systemd/user/`
3. Enable and start `dotfiles-watcher.service`

## Uninstall

```bash
./install.sh --uninstall
```

## Usage

The watcher runs automatically as a systemd user service. You can also trigger a sync manually:

```bash
dotfiles-sync
```

### Managing the service

```bash
systemctl --user status dotfiles-watcher
systemctl --user restart dotfiles-watcher
journalctl --user -u dotfiles-watcher -f
```

## How it works

```
dotfiles-watcher (daemon)
  └─ lists files tracked by ~/.cfg/
  └─ pipes to entr
       └─ on change → dotfiles-sync
            ├─ stage new systemd units in ~/.config/systemd/user/
            ├─ stage changes to tracked files
            ├─ gemini → commit message
            └─ git push origin main
```

The watcher restarts `entr` automatically when the tracked file set changes (e.g. after `git --git-dir=~/.cfg/ --work-tree=~ add <new-file>`).

## Bare repo setup

If you don't have a `~/.cfg/` bare repo yet:

```bash
git init --bare ~/.cfg/
alias cfg='git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
cfg remote add origin git@github.com:your-username/dotfiles.git
cfg config status.showUntrackedFiles no
```

## License

MIT
