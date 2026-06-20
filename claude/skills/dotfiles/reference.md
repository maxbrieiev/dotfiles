# reference — canonical guarded init snippets

All snippets are **guarded** (no error if the tool is absent) and `$HOME`-relative, so they're safe in a
config shared across accounts. Pick the file per the decision tree in SKILL.md. After editing, commit.

## Language runtimes & tools

These add PATH + completions, so they go in the `>>> tool init <<<` block of `zsh/.zshrc` unless noted.

### nvm (Node)
```zsh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
```

### bun
```zsh
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
if [ -d "$HOME/.bun/bin" ]; then export BUN_INSTALL="$HOME/.bun"; path=("$BUN_INSTALL/bin" $path); fi
```

### Rust / cargo  (PATH-only → can also go in `zsh/.zprofile`)
```zsh
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
```

### Deno  (PATH-only → `zsh/.zprofile` is fine)
```zsh
if [ -d "$HOME/.deno/bin" ]; then export DENO_INSTALL="$HOME/.deno"; path=("$DENO_INSTALL/bin" $path); fi
```

### pyenv
```zsh
if command -v pyenv >/dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"; path=("$PYENV_ROOT/bin" $path)
  eval "$(pyenv init - zsh)"
fi
```

### vite-plus
```zsh
[ -f "$HOME/.vite-plus/env" ] && . "$HOME/.vite-plus/env"
```

### ask (natural-language → shell, widget on Ctrl-X Ctrl-A)
```zsh
[ -f "$HOME/.local/share/ask/ask.zsh" ] && source "$HOME/.local/share/ask/ask.zsh"
```

## Optional shell add-ons (left out of the lean base — re-add if wanted)

Install once into the shared repo, then source. Both are gitignored like powerlevel10k if you want them
untracked, or `git add` them to vendor — your call (gitignore + bootstrap-clone keeps the repo clean).

```zsh
# git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions     /Users/Shared/dotfiles/zsh/zsh-autosuggestions
# git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting /Users/Shared/dotfiles/zsh/zsh-syntax-highlighting
```
In `zsh/.zshrc` (syntax-highlighting MUST be sourced last):
```zsh
source "$ZSH_SHARED/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$ZSH_SHARED/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
```

## Color tweaks (only if defaults look off)

```zsh
# BSD ls (macOS). Bold ANSI adapts to light/dark terminals.
export LSCOLORS="ExFxCxDxBxegedabagacad"
# GNU ls / tree / completion menus:
export LS_COLORS="di=1;34:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=1;33:cd=1;33:su=1;31:sg=1;31:tw=1;34:ow=1;34"
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# Dim autosuggestion color (if you re-added zsh-autosuggestions):
# ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
```
