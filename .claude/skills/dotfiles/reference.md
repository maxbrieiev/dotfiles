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
