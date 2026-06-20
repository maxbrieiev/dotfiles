# ~/.zprofile — login shells: environment + PATH.
# Runs once per login (every Terminal/iTerm tab on macOS), AFTER /etc/zprofile's
# path_helper, so PATH set here wins. Exported vars are inherited by all child
# processes. Source of truth: /Users/Shared/dotfiles (symlinked into ~).

# Homebrew (Apple Silicon). Guarded: a no-op until brew is installed.
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Personal bin. `typeset -U` keeps PATH entries unique across re-runs (per tab).
typeset -U path
path=("$HOME/.local/bin" $path)

export EDITOR="vim"

# Inheritable env / PATH for new tools goes here (see the `dotfiles` skill).
