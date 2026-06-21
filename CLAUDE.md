# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Single source of truth for **shell (zsh) + Claude Code config** on one Mac, shared across multiple
macOS user accounts. It lives at **`/Users/Shared/dotfiles`** (a path every account can read), **not** in
any `~`. `max` owns and commits it; each account symlinks the tracked files into its own `$HOME`. There is
no build, no test suite, and no application — "working in this repo" means editing config and committing.

Two files hold the deep background; read them before any non-trivial change:
- **README.md** — first-time machine bootstrap (clone with submodules, link the account, external deps).
- **.claude/skills/dotfiles/SKILL.md** — the model for *where* a given config line goes, plus change
  procedures; **reference.md** beside it has canonical guarded snippets.

## Invariants (these are what make the repo correct)

- **Edit here, deploy by symlink.** `link-account.sh` symlinks tracked files into each account
  (`zsh/*` → `$HOME`, `claude/*` → `~/.claude`). Editing a tracked file changes it live for every account
  the next time that file is sourced. **Commit after every change** — an uncommitted edit isn't really
  "shared." You may be invoked from another cwd, so use `git -C /Users/Shared/dotfiles …`.
- **Shared-safe means guarded + `$HOME`-relative.** A tool may be absent on a given account, so every init
  line must no-op when missing (`[[ -s "$HOME/.foo/env" ]] && source "$HOME/.foo/env"`). Never hardcode
  `/Users/max` — always `$HOME`.
- **`claude/` (no dot) ≠ `.claude/` (dot).** `claude/` is *user* Claude config (`settings.json`,
  `statusline.sh`) symlinked to `~/.claude`. `.claude/` holds the **`dotfiles` project skill** that loads
  when Claude Code runs inside this repo. The split is deliberate; don't move config between them.
- **No secrets, ever.** Claude auth stays in the macOS Keychain; `~/.claude.json` and `~/.zsh_history` are
  per-account and never tracked here.

## Where config goes (the zsh startup model)

macOS opens each terminal as a login+interactive shell. The split is deliberate — two zsh files only,
no `.zshenv`/`.zlogin`:
- **`zsh/.zprofile`** — environment + PATH. Runs after macOS `path_helper`, so PATH set here wins; exported
  vars are inherited by all child processes.
- **`zsh/.zshrc`** — interactive UX (prompt, completion, history). A tool init that adds PATH *and*
  completions goes in its `>>> tool init <<<` block.

SKILL.md has the full decision tree (including the rare `.zshenv` case for `ssh host cmd` / cron). Prefer
**invoking the `dotfiles` skill** for these edits — it encodes the routing rules and the commit step.

## Common commands

```sh
# Symlink the shared config into the current account (idempotent; backs up any real file first)
zsh .claude/skills/dotfiles/scripts/link-account.sh

# Syntax-check a zsh file before committing (closest thing to a test in this repo)
zsh -n zsh/.zshrc

# Apply zsh changes in the current shell
exec zsh

# Promote a newly-configured prompt back into the repo (after the user runs `p10k configure`)
zsh .claude/skills/dotfiles/scripts/promote-p10k.sh

# Update the powerlevel10k submodule, then commit the moved pointer
git -C zsh/powerlevel10k pull origin master
git -C /Users/Shared/dotfiles add zsh/powerlevel10k && git -C /Users/Shared/dotfiles commit -m "p10k: bump"

# A fresh clone must pull the submodule
git clone --recursive <repo-url> /Users/Shared/dotfiles   # or, after a plain clone: git submodule update --init --recursive
```

## powerlevel10k

The prompt theme is a **git submodule** at `zsh/powerlevel10k` (pinned commit). `zsh/.p10k.zsh` is the
generated prompt config: `p10k configure` writes a **real** file to `~/.p10k.zsh` (an atomic rename that
replaces the symlink), so changes land in `$HOME`, not the repo — `promote-p10k.sh` moves it back and
re-links. New accounts inherit the committed `.p10k.zsh` and never touch the wizard.
