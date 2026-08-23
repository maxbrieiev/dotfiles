#!/bin/zsh
# Link the shared dotfiles into the CURRENT account's $HOME. Idempotent & safe to re-run.
# Backs up any existing REAL file to <file>.pre-migration.bak before linking.
set -e
SHARED="/Users/Shared/dotfiles"

backup() {
  if [[ -e "$1" && ! -L "$1" ]]; then
    mv "$1" "$1.pre-migration.bak"
    echo "backed up: $1 -> $1.pre-migration.bak"
  fi
}
link() {  # link <target> <linkpath>
  backup "$2"
  ln -sfn "$1" "$2"
  echo "linked:    $2 -> $1"
}

# Ensure the powerlevel10k submodule is checked out (relevant on a fresh repo clone).
if [[ ! -e "$SHARED/zsh/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
  echo "initializing powerlevel10k submodule..."
  git -C "$SHARED" submodule update --init --recursive zsh/powerlevel10k
fi

# zsh
link "$SHARED/zsh/.zprofile" "$HOME/.zprofile"
link "$SHARED/zsh/.zshrc"    "$HOME/.zshrc"
# ~/.p10k.zsh only once it exists in the repo (created by `p10k configure`, then promoted).
[[ -e "$SHARED/zsh/.p10k.zsh" ]] && link "$SHARED/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

# Claude Code user-level config
mkdir -p "$HOME/.claude"
link "$SHARED/claude/settings.json" "$HOME/.claude/settings.json"
link "$SHARED/claude/statusline.sh" "$HOME/.claude/statusline.sh"

# Emacs. ~/.emacs.d itself stays a real per-account dir (elpa/, eln-cache/, custom.el
# are machine-generated and never shared); only the two init files are linked.
mkdir -p "$HOME/.emacs.d"
link "$SHARED/emacs/early-init.el" "$HOME/.emacs.d/early-init.el"
link "$SHARED/emacs/init.el"       "$HOME/.emacs.d/init.el"

# Shared-write git setup, so THIS account can commit to the shared repo.
# Trust the repo despite cross-account ownership (git's "dubious ownership" guard).
# Submodules are SEPARATE repos with their own ownership check, so register each
# submodule worktree (+ gitdir) too — else `git status` / submodule ops trip the guard.
register_safe_dir() {  # idempotent
  if git config --global --get-all safe.directory 2>/dev/null | grep -qx "$1"; then
    echo "git:       safe.directory already set: $1"
  else
    git config --global --add safe.directory "$1"
    echo "git:       registered safe.directory: $1"
  fi
}
register_safe_dir "$SHARED"
if [[ -f "$SHARED/.gitmodules" ]]; then
  git config --file "$SHARED/.gitmodules" --get-regexp '^submodule\..*\.path$' 2>/dev/null \
    | awk '{print $2}' | while read -r sub; do
        register_safe_dir "$SHARED/$sub"
        register_safe_dir "$SHARED/.git/modules/$sub"
      done
fi
# Heads-up if this account can't actually write yet (group not active / not added).
if ! id -Gn | tr ' ' '\n' | grep -qx dotfiles; then
  echo "NOTE: '$USER' is not in the 'dotfiles' group in this session — you can't commit yet."
  echo "      An admin runs once:  sudo zsh $SHARED/.claude/skills/dotfiles/scripts/enable-shared-writes.sh"
  echo "      then log out/in (group membership refreshes on login)."
fi
# Commits need an identity.
if [[ -z "$(git -C "$SHARED" config --get user.name || true)" || -z "$(git -C "$SHARED" config --get user.email || true)" ]]; then
  echo "NOTE: set a git identity to commit:"
  echo "      git config --global user.name 'Your Name' && git config --global user.email 'you@example.com'"
fi

echo
echo "Done. Open a new shell (or 'exec zsh')."
[[ -e "$SHARED/zsh/.p10k.zsh" ]] || echo "Prompt not configured yet — run 'p10k configure', then promote ~/.p10k.zsh into the repo."
