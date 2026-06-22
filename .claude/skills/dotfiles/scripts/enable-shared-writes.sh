#!/bin/zsh
# enable-shared-writes.sh — make /Users/Shared/dotfiles writable by EVERY account
# that shares this config, so each one edits & commits as an equal (not max-only).
#
# Run ONCE per machine, by an admin:
#     sudo zsh .claude/skills/dotfiles/scripts/enable-shared-writes.sh [account ...]
# (it self-elevates if you forget `sudo`). Default accounts: max max-ounass.
# Idempotent — safe to re-run, e.g. to add a new collaborator:
#     sudo zsh .../enable-shared-writes.sh max max-ounass alice
#
# Mechanism (the "shared writable git repo" recipe, macOS-native):
#   * a dedicated POSIX group owns the repo, group-writable + setgid dirs;
#   * an INHERITED ACL grants the group rw on every NEW file too (beats umask 022);
#   * git core.sharedRepository=group keeps .git group-writable as git writes objects.
# Per-account `safe.directory` (git's cross-owner "dubious ownership" guard) is handled
# separately by link-account.sh, which each account runs for itself.
set -eu

REPO="/Users/Shared/dotfiles"
GROUP="dotfiles"   # hardcoded: link-account.sh and the docs reference this name literally
SELF="${0:A}"

# Inheriting ACL applied to DIRECTORIES only: files & subdirs created under them
# inherit a group rw ACE automatically (this is what beats umask 022 for NEW files).
# EXISTING files are made group-writable by the POSIX `chmod -R g+rwX` below, so they
# need no explicit ACE — which also avoids leaving a redundant inherited+explicit ACE
# pair on the bulk of the repo (e.g. git objects) when this script is re-run.
ACL_DIR="group:$GROUP allow list,search,add_file,add_subdirectory,delete,delete_child,readattr,writeattr,readextattr,writeextattr,readsecurity,file_inherit,directory_inherit"

# Need root to create the group and chgrp files we may not own. Re-exec under sudo.
if (( EUID != 0 )); then
  echo "==> Elevating (need admin to create the group and set ownership)…"
  exec sudo -p "Admin password to enable shared writes: " zsh "$SELF" "$@"
fi

if (( $# )); then members=("$@"); else members=(max max-ounass); fi

echo "==> Ensuring group '$GROUP' exists"
if dscl . -read "/Groups/$GROUP" >/dev/null 2>&1; then
  echo "    exists"
else
  dseditgroup -o create "$GROUP"
  echo "    created"
fi

echo "==> Group members"
for u in "${members[@]}"; do
  if ! id "$u" >/dev/null 2>&1; then echo "    skip '$u' (no such account)"; continue; fi
  if dseditgroup -o checkmember -m "$u" "$GROUP" >/dev/null 2>&1; then
    echo "    $u already a member"
  else
    dseditgroup -o edit -a "$u" -t user "$GROUP"
    echo "    added $u"
  fi
done

echo "==> Group-owning the repo, group-writable, setgid dirs (POSIX baseline)"
chgrp -R "$GROUP" "$REPO"
chmod -R g+rwX "$REPO"               # existing files/dirs writable by the group
find "$REPO" -type d -exec chmod g+s {} +   # new files inherit the group

echo "==> Inheriting ACL on directories so NEW files stay group-writable (beats umask)"
find "$REPO" -type d -exec chmod +a "$ACL_DIR" {} +

echo "==> git: keep .git (and each submodule) group-writable as objects/refs are written"
# -c safe.directory: chgrp changes only the GROUP, so the repo stays owned by whoever
# created it. When a DIFFERENT admin runs this via sudo, the root git process would
# otherwise abort on git's cross-owner "dubious ownership" guard. -c clears it.
git -C "$REPO" -c safe.directory="$REPO" config core.sharedRepository group
# Submodules (e.g. zsh/powerlevel10k) are separate repos with their own config — give
# each initialized one the same shared mode so a `p10k: bump` by any member keeps its
# objects group-writable too.
if [[ -d "$REPO/.git/modules" ]]; then
  find "$REPO/.git/modules" -maxdepth 3 -type f -name config -print | while read -r cfg; do
    gd="${cfg:h}"
    git --git-dir="$gd" -c safe.directory="$gd" config core.sharedRepository group 2>/dev/null || true
  done
fi

echo
echo "Done. The repo is now writable by the '$GROUP' group."
echo "Each account must still run link-account.sh once (registers git safe.directory)."
echo "A just-added member must LOG OUT and BACK IN before its session has the group."
ls -ledn "$REPO" | sed -n '1,6p'
