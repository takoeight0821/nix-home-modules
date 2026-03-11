# nix-home-modules

Reusable [home-manager](https://github.com/nix-community/home-manager) and [nix-darwin](https://github.com/nix-darwin/nix-darwin) modules for macOS.

Provides opinionated defaults for shell, editor, terminal, and development tool configurations — all managed declaratively with Nix Flakes.

## Quick Start

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-home-modules = {
      url = "github:takoeight0821/nix-home-modules";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { nixpkgs, home-manager, nix-home-modules, ... }: {
    homeConfigurations."user" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      modules = [
        nix-home-modules.homeManagerModules.default
        {
          takoeight0821.programs.shell.enable = true;
          takoeight0821.programs.packages.enable = true;
          takoeight0821.programs.claude-hooks.enable = true;
        }
      ];
    };
  };
}
```

## Flake Outputs

| Output | Description |
|---|---|
| `homeManagerModules.default` | All home-manager modules |
| `darwinModules.default` | nix-darwin system modules |
| `lib.mkMutableConfig` | Create mutable config files with baseline tracking |
| `lib.convertPlugin` | Convert Claude Code plugins to home-manager format |
| `formatter` | `nixfmt` for code formatting |
| `checks` | Hook test suite |

## Directory Structure

```
nix-home-modules/
├── lib/                    → Library API
│   ├── mkMutableConfig.nix
│   └── convert-plugin.nix
├── modules/
│   ├── home/               → Home-manager modules
│   │   ├── shell.nix
│   │   ├── neovim.nix
│   │   ├── ghostty.nix
│   │   ├── tmux.nix
│   │   ├── vscode/
│   │   ├── iterm2/
│   │   ├── karabiner.nix
│   │   ├── packages.nix
│   │   ├── codex.nix
│   │   ├── gemini.nix
│   │   ├── claude-hooks.nix
│   │   └── hooks/          → Claude Code safety hooks
│   └── darwin/             → nix-darwin modules
│       └── defaults.nix
└── tests/                  → Hook tests
```

See also:
- [Library API](lib/README.md)
- [Home Modules](modules/home/README.md)
- [Claude Code Hooks](modules/home/hooks/README.md)
- [Darwin Modules](modules/darwin/README.md)
- [Tests](tests/README.md)

## Platform

macOS only (`aarch64-darwin`, `x86_64-darwin`).

## Privacy

This repository is public. It must never contain personal identifiers, company names, email addresses, SSH keys, or credentials.
