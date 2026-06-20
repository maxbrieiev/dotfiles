# dotfiles

Single source of truth for **shell + Claude Code config** on this Mac, shared across user accounts.
Owned by `max` (mode `755`); each account symlinks these files into `$HOME`. Lives in `/Users/Shared`
(not `/etc`, which macOS resets on OS updates).

## Layout
| Path | What |
|---|---|
| `zsh/.zprofile` | login shell — environment + PATH (`brew shellenv`, `~/.local/bin`, `EDITOR`) |
| `zsh/.zshrc` | interactive shell — powerlevel10k, `compinit`, history, `CLICOLOR` |
| `zsh/.p10k.zsh` | powerlevel10k prompt config (from `p10k configure`) |
| `zsh/powerlevel10k/` | powerlevel10k theme — git **submodule** (pinned commit) |
| `claude/settings.json`, `claude/statusline.sh` | shared Claude Code config |
| `claude/skills/dotfiles/` | the **`dotfiles`** skill — documents & performs all maintenance |

## Common tasks
- **Onboard a new account:** `zsh claude/skills/dotfiles/scripts/link-account.sh`
- **Fresh-machine clone:** `git clone --recursive <url>` (or `git submodule update --init --recursive`)
- **Add a tool's shell init / re-add an add-on / change config:** use the **`dotfiles`** skill (`/dotfiles`).
  It encodes the where-does-it-go rules and does the edit + commit.
- **Update powerlevel10k:** `git -C zsh/powerlevel10k pull origin master`, then commit the submodule pointer.

## Design, in brief
Two zsh files only — environment/PATH in `.zprofile`, interactive UX in `.zshrc` (no `.zshenv`/`.zlogin`).
Lean prompt: powerlevel10k sourced directly, **no oh-my-zsh**. Claude auth is **never** in this repo —
it stays per-account in the macOS Keychain (`~/.claude.json` is not shared). The **`dotfiles` skill**
(`claude/skills/dotfiles/SKILL.md`) holds the full reasoning and step-by-step procedures.
