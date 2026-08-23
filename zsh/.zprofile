# ~/.zprofile — login shells: environment + PATH.
# Runs once per login (every terminal tab / Emacs shell on macOS), AFTER /etc/zprofile's
# path_helper, so PATH set here wins. Exported vars are inherited by all child
# processes. Source of truth: /Users/Shared/dotfiles (symlinked into ~).

# Homebrew (Apple Silicon). Guarded: a no-op until brew is installed.
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Personal bin. `typeset -U` keeps PATH entries unique across re-runs (per tab).
typeset -U path
path=("$HOME/.local/bin" $path)

# Editor: emacsclient (the Emacs config starts the server, so this opens in the
# running frame). Guarded: unset on accounts without Emacs.
(( $+commands[emacsclient] )) && export EDITOR="emacsclient" VISUAL="emacsclient"

# Inheritable env / PATH for new tools goes here (see the `dotfiles` skill).
