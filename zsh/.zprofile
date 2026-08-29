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

# Node for GUI apps and login shells (Emacs spawns `tsc --lsp`, `oxfmt` from this PATH).
# nvm itself (the `nvm` function) loads in .zshrc; here only the newest installed
# version's bin goes on PATH, resolved by glob so nvm's alias chain isn't needed.
# Guarded: a no-op until nvm has installed a version.
() { local -a nodes; nodes=("$HOME"/.nvm/versions/node/v*/bin(N/nOn)); (( $#nodes )) && path=("$nodes[1]" $path) }

# pnpm (standalone install: `curl -fsSL https://get.pnpm.io/install.sh | sh -`). Its global
# bin holds `pnpm` and `pnpm add -g` tools (tsc for Emacs's eglot). Guarded: no-op where absent.
# NOTE: the installer's `pnpm setup` appends this to ~/.zshrc, replacing the symlink with a real
# file — re-run link-account.sh afterwards; the block lives here instead (PATH belongs in .zprofile).
if [[ -d "$HOME/Library/pnpm/bin" ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
  path=("$PNPM_HOME/bin" $path)
fi

# Inheritable env / PATH for new tools goes here (see the `dotfiles` skill).
