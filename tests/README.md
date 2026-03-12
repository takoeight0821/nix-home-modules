# Tests

Hook tests that run as part of `nix flake check`.

## Running Tests

```bash
nix flake check
```

All tests run in a sandboxed Nix build environment. They build a home-manager configuration with `claude-hooks` enabled, extract the generated hook scripts, and run test cases against them.

## Test Suite

| Test | Script Under Test | Cases |
|---|---|---|
| `test-block-dangerous-flags` | `block-dangerous-flags.sh` | ~50 cases |
| `test-git-readonly-approve` | `git-readonly-approve.sh` | ~50 cases |

## How Tests Work

Each test script:

1. Accepts `--script <path>` to locate the hook script
2. Feeds JSON input via stdin: `{ "tool_input": { "command": "<cmd>" } }`
3. Checks the hook's JSON output (or lack of output) against expected behavior
4. Prints a PASS/FAIL summary and exits non-zero on any failure

### Test Categories

**test-block-dangerous-flags.sh:**
- True positives: `sed -i`, `find -delete`, `fd --exec`, `sort -o`, `nix store gc`, `nix-env --uninstall`
- True negatives: safe versions of the same commands
- False positive prevention: dangerous patterns inside quoted strings

**test-git-readonly-approve.sh:**
- Approved: read-only git with global flags (`-C`, `--no-pager`, `-c`, `--git-dir`)
- Safe stash: `stash list`, `stash show`
- Fallthrough: write operations (`push`, `commit`, `reset`, `checkout`)
- Chain handling: `safe && safe`, `safe && unsafe`
- False positive prevention: git commands inside `echo` or commit messages

## Adding New Tests

1. Create `tests/test-<name>.sh` following the existing pattern
2. Add a `checks` entry in `flake.nix` that builds the hook script and runs the test
3. Run `nix flake check` to verify
