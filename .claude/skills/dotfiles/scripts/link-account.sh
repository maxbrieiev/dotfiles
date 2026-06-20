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

echo
echo "Done. Open a new shell (or 'exec zsh')."
[[ -e "$SHARED/zsh/.p10k.zsh" ]] || echo "Prompt not configured yet — run 'p10k configure', then promote ~/.p10k.zsh into the repo."
