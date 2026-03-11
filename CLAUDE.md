# nix-home-modules

Reusable home-manager and nix-darwin modules.

## Privacy

This repository is intended to be public. **Never** include:
- Personal identifiers (usernames, employee IDs)
- Company names or internal domain names
- Email addresses or real names
- SSH keys or credentials

Run `nix flake check` before committing to verify no private information leaks.

## Structure

```
lib/           - Shared library functions (mkMutableConfig, convertPlugin)
modules/home/  - home-manager modules (takoeight0821.programs.*)
modules/darwin/- nix-darwin modules (takoeight0821.darwin.*)
tests/         - Hook test scripts
```

## Module Convention

Each module uses the `takoeight0821.programs.<name>.enable` option pattern.
Modules receive `nhm-lib` via `_module.args` for shared utilities.
