# dotfiles

Single source of truth for **shell + Claude Code config** on this Mac, shared across macOS user accounts.

## Where it lives — the shared directory, not a home directory
Clone this repo into **`/Users/Shared/dotfiles`**, *not* into any user's `~`. `/Users/Shared` is readable
by every account on the Mac, so the personal and work accounts use the **same** copy. A clone under
`~/dotfiles` would be private to one account and couldn't be shared. The repo is owned by `max` (mode
`755`): every account reads it, only `max` edits/commits; each account then symlinks the files into its
own `$HOME` (via `link-account.sh`). It lives in `/Users/Shared` rather than `/etc`, which macOS resets
on OS updates.

## Bootstrap a new machine
The `dotfiles` skill is a **project skill** (it ships inside `.claude/` in this repo), so it's available
the moment you open Claude Code in the clone — no pre-existing `~/.claude` setup, no chicken-and-egg.

1. **Install Claude Code** (native installer) and log in. *(User step — the skill can't install its own runtime.)*
2. **Clone into the shared dir**, with submodules:
   `git clone --recursive <repo-url> /Users/Shared/dotfiles`   ← shared dir, **not** `~`.
3. `cd /Users/Shared/dotfiles && claude` — the `dotfiles` skill loads automatically.
4. Ask it to set up the account (or run directly):
   `zsh .claude/skills/dotfiles/scripts/link-account.sh` — symlinks the config into `$HOME` + `~/.claude`
   and inits the p10k submodule.
5. **Install Homebrew**, then `brew install jq` and the **MesloLGS NF** font. *(User steps — preexisting deps.)*
6. Open a new terminal. The prompt **inherits** the committed `.p10k.zsh` automatically — no wizard needed.
   (Only to *change* the prompt do you run `p10k configure`; powerlevel10k also auto-launches it if
   `~/.p10k.zsh` is ever missing.)

## Layout
| Path | What |
|---|---|
| `zsh/.zprofile` | login shell — environment + PATH (`brew shellenv`, `~/.local/bin`, `EDITOR`) |
| `zsh/.zshrc` | interactive shell — powerlevel10k, `compinit`, history, `CLICOLOR` |
| `zsh/.p10k.zsh` | powerlevel10k prompt config |
| `zsh/powerlevel10k/` | powerlevel10k theme — git **submodule** (pinned commit) |
| `claude/settings.json`, `claude/statusline.sh` | user-level Claude config — symlink sources for `~/.claude` |
| `.claude/skills/dotfiles/` | the **`dotfiles`** project skill — maintenance helper |

> `claude/` is **no-dot** on purpose: its `settings.json` is *user* config (symlinked to `~/.claude`), not
> project config. Only the skill lives under `.claude/`, so opening Claude here exposes the skill and nothing else.

## Everyday maintenance (run `claude` inside this repo)
- **Add a tool's shell init / change config:** invoke the **`dotfiles`** skill — it knows
  the where-does-it-go rules and does the edit + commit.
- **Add another account on this Mac:** `zsh .claude/skills/dotfiles/scripts/link-account.sh`.
- **Update powerlevel10k:** `git -C zsh/powerlevel10k pull origin master`, then commit the submodule pointer.

## Design, in brief
Two zsh files only — environment/PATH in `.zprofile`, interactive UX in `.zshrc` (no `.zshenv`/`.zlogin`).
Lean prompt: powerlevel10k sourced directly, **no oh-my-zsh**. Claude auth is **never** in this repo —
it stays per-account in the macOS Keychain (`~/.claude.json` is not shared). See
`.claude/skills/dotfiles/SKILL.md` for the full reasoning and procedures.
