#!/bin/zsh
# promote-p10k.sh — after `p10k configure`, move the freshly generated ~/.p10k.zsh
# into the shared repo, re-symlink it back, and commit. Idempotent.
#
# Why this exists: `p10k configure` writes a REAL file to ~/.p10k.zsh (an atomic
# rename that replaces the repo symlink), so the new prompt config lands in $HOME,
# not the shared repo. This promotes it back. New accounts never need this — they
# inherit the shared config via link-account.sh.
set -e
SHARED="/Users/Shared/dotfiles"
SRC="$HOME/.p10k.zsh"
DST="$SHARED/zsh/.p10k.zsh"

if [[ -L "$SRC" ]]; then
  echo "~/.p10k.zsh is already a symlink into the repo — nothing to promote."
  echo "(Run \`p10k configure\` first if you want to change the prompt.)"
  exit 0
fi
[[ -f "$SRC" ]] || { echo "No ~/.p10k.zsh found — run \`p10k configure\` first."; exit 1; }

mv -f "$SRC" "$DST"
ln -sfn "$DST" "$SRC"
echo "promoted: ~/.p10k.zsh -> $DST"

git -C "$SHARED" add zsh/.p10k.zsh
if git -C "$SHARED" diff --cached --quiet; then
  echo "no changes to commit."
else
  git -C "$SHARED" commit -q -m "p10k: update prompt config"
  echo "committed."
fi
