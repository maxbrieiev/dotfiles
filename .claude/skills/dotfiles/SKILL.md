---
name: dotfiles
description: >-
  Maintain the shared zsh + Claude Code dotfiles repo at /Users/Shared/dotfiles (a project
  skill living in that repo). Use when changing the shared config from inside the repo: adding
  a CLI tool's shell init ("I installed deno/bun/rust"), promoting a new powerlevel10k prompt,
  bumping the p10k submodule, or linking the config into another account.
---

# dotfiles — shared shell + Claude Code config

This Mac shares one source-of-truth config between multiple macOS user accounts. (First-time machine
**setup/bootstrap lives in the repo README**; this skill is for changes you make while Claude Code is
already running inside the repo.)

- **Source of truth:** `/Users/Shared/dotfiles` — a **git repo**, owned by `max`, mode `755`
  (every account reads; only `max` edits/commits).
- **This is a project skill** (`.claude/skills/dotfiles/`): it loads whenever `claude` runs inside this repo.
- **Config is deployed via symlinks** into each account by `scripts/link-account.sh` (zsh files → `$HOME`,
  `settings.json`/`statusline.sh` → `~/.claude`). The skill itself is NOT symlinked.
- **Layout:** `zsh/` (`.zprofile`, `.zshrc`, `.p10k.zsh`, `powerlevel10k/` submodule),
  `claude/` (`settings.json`, `statusline.sh`), `.claude/skills/dotfiles/` (this skill).

When you change anything here, **commit it**: `git -C /Users/Shared/dotfiles add -A && git -C /Users/Shared/dotfiles commit -m "..."`.

## The zsh startup-file model (decides WHERE init goes)

macOS opens each terminal tab as a **login + interactive** shell. Load order:
`/etc/zshenv → ~/.zshenv → /etc/zprofile (path_helper) → ~/.zprofile → /etc/zshrc → ~/.zshrc`.

Key facts:
- A **non-interactive non-login** shell (`ssh host cmd`, cron, `zsh -c`) reads **only `~/.zshenv`**.
- macOS `path_helper` (in `/etc/zprofile`) **reorders PATH**, so PATH set in `~/.zshenv` loses and PATH
  set in `~/.zprofile` (runs after) wins.
- Exported env is inherited by all child processes.

**Decision tree — where to add an init line:**

| What you're adding | File | Notes |
|---|---|---|
| PATH entry or exported env var (the common case) | `zsh/.zprofile` | runs after path_helper; inherited everywhere |
| Interactive-only (alias, function, keybinding, prompt/plugin) | `zsh/.zshrc` | inside the `>>> tool init <<<` block for tool inits |
| Env/PATH a `ssh host cmd` / cron job needs | create `zsh/.zshenv` + add a symlink | only then; keep it tiny, no output |
| Account-specific (work git email, work-only tool) | `~/.zshrc.local` (real file, NOT shared) | not in this repo |

**Always guard** so the shared config never errors when a tool is absent on an account:
`[[ -s "$HOME/.foo/env" ]] && source "$HOME/.foo/env"` — and use `$HOME`, never `/Users/max`.

## Procedure: add a CLI tool's shell init (e.g. "I installed deno")

1. Look up the canonical guarded snippet in [reference.md](reference.md). If the tool isn't in that
   catalog, write a minimal guarded, `$HOME`-relative snippet and **add it to reference.md** — the catalog
   is meant to grow as tools are installed.
2. Decide the file from the decision tree above (most runtimes → a guarded block in `zsh/.zshrc`'s
   `>>> tool init <<<` section, since they add PATH *and* completions; pure PATH-only → `zsh/.zprofile`).
3. Edit the file in `/Users/Shared/dotfiles`. Keep it guarded and `$HOME`-relative.
4. `git -C /Users/Shared/dotfiles add -A && git -C /Users/Shared/dotfiles commit -m "zsh: add <tool>"`.
5. Tell the user to open a new shell (or `exec zsh`) to pick it up.

## Procedure: promote a new prompt config

Changing the prompt is a **user** action — they run `p10k configure` (or delete `~/.p10k.zsh`, which makes
powerlevel10k auto-launch the wizard on the next shell). That writes a **real** `~/.p10k.zsh`, replacing the
repo symlink. The skill's only job is to **promote** it back into the repo:
`zsh /Users/Shared/dotfiles/.claude/skills/dotfiles/scripts/promote-p10k.sh` — moves it into `zsh/.p10k.zsh`, re-symlinks, and commits.
(New accounts never touch the wizard — they inherit the committed `.p10k.zsh` via `link-account.sh`.)

## Notes
- `scripts/link-account.sh` (re)creates this account's symlinks + inits the p10k submodule. It's a setup
  step — see the repo **README** for first-time machine bootstrap.
- powerlevel10k is a git **submodule** (pinned commit). Update with:
  `git -C /Users/Shared/dotfiles/zsh/powerlevel10k pull origin master` then
  `git -C /Users/Shared/dotfiles add zsh/powerlevel10k && git -C /Users/Shared/dotfiles commit -m "p10k: bump"`.
  A fresh clone needs `git submodule update --init --recursive`.
- Never put secrets here. Claude auth lives in the macOS Keychain; `~/.claude.json` stays per-account.
