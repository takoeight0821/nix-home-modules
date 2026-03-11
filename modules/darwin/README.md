# Darwin Modules

nix-darwin modules for macOS system configuration.

## defaults.nix

Configures macOS system defaults and Homebrew packages.

```nix
takoeight0821.darwin.defaults.enable = true;
```

### Options

| Option | Type | Default | Description |
|---|---|---|---|
| `enable` | bool | `false` | Enable macOS defaults and Homebrew |
| `extraBrews` | list of string | `[]` | Additional Homebrew formulae |
| `extraCasks` | list of string | `[]` | Additional Homebrew casks |

### System Defaults

| Setting | Value |
|---|---|
| Show all file extensions | `true` |
| Initial key repeat delay | 15 |
| Key repeat rate | 2 |
| Finder: pathbar, status bar | enabled |
| Dock: auto-hide | `true` |
| Dock: show recent apps | `false` |
| Caps Lock → Control | enabled |

### Default Homebrew Packages

**Formulae:** aws-sam-cli, gemini-cli

**Casks:** ghostty, visual-studio-code, orbstack, claude, codex, antigravity, iterm2, raycast, microsoft-edge, karabiner-elements, logseq, font-hackgen, font-hackgen-nerd

### Adding Packages

```nix
takoeight0821.darwin.defaults = {
  enable = true;
  extraBrews = [ "postgresql" ];
  extraCasks = [ "firefox" "slack" ];
};
```
