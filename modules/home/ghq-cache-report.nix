{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.takoeight0821.programs.ghq-cache-report;

  ghq-cache-report = pkgs.writeShellApplication {
    name = "ghq-cache-report";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      ghq
    ];
    text = ''
      set -euo pipefail

      usage() {
        cat <<'EOF'
      Usage: ghq-cache-report [-n N] [-r ROOT]

      Scan the ghq repository root for well-known build/cache directories
      and list them sorted by size (largest first).

      Options:
        -n N     Show only top N entries (default: all)
        -r ROOT  Use ROOT instead of the ghq root directory
        -h       Show this help

      Detected directory names:
        node_modules, target, dist, build, out,
        .venv, venv, __pycache__,
        .gradle, .next, .nuxt, .turbo, .parcel-cache,
        vendor, _build, .stack-work, .mix,
        coverage, .cache, result
      EOF
      }

      N=""
      ROOT=""

      while getopts ":n:r:h" opt; do
        case "$opt" in
          n) N="$OPTARG" ;;
          r) ROOT="$OPTARG" ;;
          h) usage; exit 0 ;;
          :) printf 'error: -%s requires an argument\n' "$OPTARG" >&2; exit 1 ;;
          \?) printf 'error: unknown option -%s\n' "$OPTARG" >&2; usage >&2; exit 1 ;;
        esac
      done

      if [ -n "$N" ]; then
        case "$N" in
          "" | *[!0-9]*)
            printf 'error: -n must be a positive integer, got: %s\n' "$N" >&2
            exit 1
            ;;
        esac
      fi

      if [ -z "$ROOT" ]; then
        if ! ROOT="$(ghq root 2>/dev/null)"; then
          printf 'error: ghq root failed (is ghq configured?)\n' >&2
          exit 1
        fi
      fi

      if [ ! -d "$ROOT" ]; then
        printf 'error: not a directory: %s\n' "$ROOT" >&2
        exit 1
      fi

      patterns=(
        node_modules target dist build out
        .venv venv __pycache__
        .gradle .next .nuxt .turbo .parcel-cache
        vendor _build .stack-work .mix
        coverage .cache result
      )

      find_args=()
      for i in "''${!patterns[@]}"; do
        if [ "$i" -gt 0 ]; then
          find_args+=(-o)
        fi
        find_args+=(-name "''${patterns[$i]}")
      done

      output="$(
        find "$ROOT" -type d \( "''${find_args[@]}" \) -prune -print0 2>/dev/null \
          | xargs -0 -r du -sh 2>/dev/null \
          | sort -hr
      )"

      if [ -z "$output" ]; then
        printf 'no matching cache directories found under %s\n' "$ROOT"
        exit 0
      fi

      if [ -n "$N" ]; then
        printf '%s\n' "$output" | head -n "$N"
      else
        printf '%s\n' "$output"
      fi
    '';
  };
in
{
  options.takoeight0821.programs.ghq-cache-report = {
    enable = lib.mkEnableOption "ghq-cache-report (list build/cache dirs under ghq root)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ ghq-cache-report ];
  };
}
