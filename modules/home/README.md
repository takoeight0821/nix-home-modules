# Home-Manager Modules

All modules use the `takoeight0821.programs.<name>` option namespace and follow a consistent pattern:

```nix
takoeight0821.programs.<name>.enable = true;
```

## Module List

| Module | Option | Description |
|---|---|---|
| `shell.nix` | `shell` | Zsh with starship, direnv, fzf, vi-mode, aliases |
| `neovim.nix` | `neovim` | Neovim IDE with treesitter, telescope, LSP, completion |
| `ghostty.nix` | `ghostty` | Ghostty terminal (configurable font and size) |
| `iterm2/` | `iterm2` | iTerm2 with Nord color scheme |
| `tmux.nix` | `tmux` | tmux with resurrect/continuum plugins |
| `vscode/` | `vscode` | VS Code with extensions and mutable settings |
| `karabiner.nix` | `karabiner` | Karabiner-Elements keyboard remapping |
| `packages.nix` | `packages` | Common CLI tools (ripgrep, fd, jq, gh, etc.) |
| `codex.nix` | `codex` | Codex AI tool configuration |
| `gemini.nix` | `gemini` | Google Gemini CLI configuration |
| `claude-hooks.nix` | `claude-hooks` | Claude Code settings, permissions, and safety hooks |

## Notable Options

### shell

Installs zsh with 50,000-line history, starship prompt, direnv, and fzf. Includes aliases (`gs`, `gd`, `ga`, `gc`, `gp`, `gl` for git) and utility functions (`fzf-src`, `fzf-code`, `copymd`).

### packages

Installs common CLI/development tools. Add more via:

```nix
takoeight0821.programs.packages = {
  enable = true;
  extraPackages = with pkgs; [ nodejs rustup ];
};
```

### ghostty

```nix
takoeight0821.programs.ghostty = {
  enable = true;
  font = "PlemolJP Console NF";  # default: "HackGen Console NF"
  fontSize = 16;                  # default: 14
};
```

### claude-hooks

See [Claude Code Hooks](hooks/README.md) for details on the safety hook system.

Key options:
- `extraAllowPermissions` / `extraDenyPermissions` — extend permission lists
- `extraPreToolUseHooks` / `extraPostToolUseHooks` — add custom hooks
- `extraEnabledPlugins` — enable/disable Claude Code plugins
- `extraSettings` — merge additional top-level settings

### karabiner

Configures Karabiner-Elements with ESC-in-Japanese-IME and HHKB function key mappings. Uses mutable config (see [mkMutableConfig](../../lib/README.md#mkmutableconfig)).

```nix
takoeight0821.programs.karabiner = {
  enable = true;
  externalKeyboards = [
    { vendor_id = 1234; product_id = 5678; }
  ];
};
```

## nhm-lib

All modules receive `nhm-lib` via `_module.args`, providing access to `mkMutableConfig` and `convertPlugin`. See [Library API](../../lib/README.md).
