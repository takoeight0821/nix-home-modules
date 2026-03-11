# Library API

Shared utility functions exported via `flake.lib` and available in modules as `nhm-lib`.

## mkMutableConfig

Creates config files that can be edited manually by the user while maintaining a Nix-managed baseline.

### Problem

home-manager manages files via read-only symlinks into the Nix store. Some applications (VS Code, Karabiner-Elements, Codex, Gemini CLI) require writable config files.

### Solution

Writes a real file alongside a `.nix-baseline` sidecar. On rebuild:
1. If the file is a symlink, removes it (migration from symlink-managed state)
2. Compares the baseline with the actual file
3. If the user has made manual edits, shows a diff warning before overwriting
4. Updates both the file and baseline when the Nix config changes
5. Leaves the file untouched if the Nix config hasn't changed

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `name` | string | Display name for warning messages |
| `configContent` | string | The Nix-managed file content |
| `targetPath` | string | Path relative to `$HOME` (e.g. `".config/karabiner/karabiner.json"`) |

### Usage

In a module (where `nhm-lib` is available via `_module.args`):

```nix
{ nhm-lib, ... }:
{
  home.activation.myAppConfig = nhm-lib.mkMutableConfig {
    name = "my-app";
    configContent = builtins.toJSON { setting = "value"; };
    targetPath = ".config/my-app/config.json";
  };
}
```

### Used by

- `karabiner.nix` — Karabiner-Elements configuration
- `vscode/default.nix` — VS Code settings.json
- `codex.nix` — Codex configuration
- `gemini.nix` — Gemini CLI configuration
- `iterm2/default.nix` — iTerm2 preferences

## convertPlugin

Converts Claude Code plugins from the [plugins-official](https://github.com/anthropics/claude-code-plugins-official) format into home-manager compatible file entries and hook configurations.

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `name` | string | Plugin name (used for hook file paths) |
| `pluginRoot` | path | Path to the plugin directory |

### Return Value

An attribute set with three fields:

| Field | Type | Description |
|---|---|---|
| `skills` | derivation | Nix store path containing transformed skill files |
| `hookFiles` | attrset | home-manager `home.file` entries for hook scripts |
| `hookEntries` | attrset | Hook configuration entries for `settings.json` |

### Transformations

- **`skills/`** → copied as-is
- **`agents/*.md`** → skills with `tools:` renamed to `allowed-tools:` and `color:` removed
- **`commands/*.md`** → skills with `argument-hint:` removed
- **`hooks/hooks.json`** → hook entries with `${CLAUDE_PLUGIN_ROOT}/hooks/` replaced by `bash ~/.claude/hooks/{name}/`
- **Hook script files** → installed to `~/.claude/hooks/{name}/`

### Usage

```nix
{ nhm-lib, ... }:
let
  plugin = nhm-lib.convertPlugin {
    name = "my-plugin";
    pluginRoot = ./path/to/plugin;
  };
in
{
  home.file = plugin.hookFiles;
  # Use plugin.skills and plugin.hookEntries as needed
}
```
