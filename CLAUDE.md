# nix-home-modules — Development Guide

Reusable home-manager and nix-darwin modules for macOS. See [README.md](README.md) for user documentation.

## Privacy

This repository is **public**. Never include:
- Personal identifiers (usernames, employee IDs)
- Company names or internal domain names
- Email addresses or real names
- SSH keys or credentials

Run `nix flake check` before every commit.

## Coding Conventions

### Nix Style

- Format with `nixfmt` (`nix fmt`)
- Module option namespace: `takoeight0821.programs.<name>` (home) or `takoeight0821.darwin.<name>` (darwin)
- Module pattern:
  ```nix
  { config, lib, pkgs, ... }:
  let
    cfg = config.takoeight0821.programs.<name>;
  in
  {
    options.takoeight0821.programs.<name> = {
      enable = lib.mkEnableOption "<description>";
    };
    config = lib.mkIf cfg.enable { /* ... */ };
  }
  ```
- Use `nhm-lib` (available via `_module.args`) for `mkMutableConfig` and `convertPlugin`
- Use `lib.mkIf`, `lib.mkMerge`, `lib.optionalAttrs`, `lib.optionals` for conditionals

### Hook Scripts

- Bash scripts receiving JSON via stdin, outputting JSON to stdout
- Strip quoted strings before pattern matching to prevent false positives
- Use word boundaries in regex for command detection

## Claude Code Plugin Management

- `modules/home/claude-plugins.nix` — declarative Claude Code plugin management (`takoeight0821.programs.claude-plugins`). Populates `~/.claude/plugins/` from flake-input marketplace sources and optionally syncs GitHub Copilot CLI (`~/.copilot`); `copilotCli.declarative` prunes anything not declared in Nix.
- `lib/convert-plugin.nix` (`nhm-lib.convertPlugin`) — converts a plugin's `agents/` and `commands/` into skills and deploys its `hooks/`/`scripts/`/`prompts/`, rewriting `${CLAUDE_PLUGIN_ROOT}` to a deployed path.

## Commands

```bash
nix flake check    # Run tests + validate
nix fmt            # Format all .nix files
```

## Tests

Two hook test suites run via `nix flake check`:

| Test | What it tests |
|---|---|
| `test-block-dangerous-flags` | Destructive command blocking (~50 cases) |
| `test-git-readonly-approve` | Read-only git auto-approval (~50 cases) |

See [tests/README.md](tests/README.md) for details.
