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
      gawk
      ghq
    ];
    text = ''
      set -euo pipefail

      usage() {
        cat <<'EOF'
      Usage: ghq-cache-report [-s] [-n N] [-r ROOT]

      Scan the ghq repository root for well-known build/cache directories
      and list them sorted by size (largest first).

      Options:
        -s       Summarize per repo (host/owner/repo) instead of per directory
        -n N     Show only top N entries (default: all)
        -r ROOT  Use ROOT instead of the ghq root directory
        -h       Show this help

      Detected directory names:
        node_modules, target, dist, build, out,
        .venv, venv, __pycache__,
        .gradle, .next, .nuxt, .turbo, .parcel-cache,
        vendor, _build, .stack-work, .mix,
        .terraform, .terragrunt-cache,
        coverage, .cache, result
      EOF
      }

      N=""
      ROOT=""
      BY_REPO=0

      while getopts ":n:r:sh" opt; do
        case "$opt" in
          n) N="$OPTARG" ;;
          r) ROOT="$OPTARG" ;;
          s) BY_REPO=1 ;;
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
        .terraform .terragrunt-cache
        coverage .cache result
      )

      find_args=()
      for i in "''${!patterns[@]}"; do
        if [ "$i" -gt 0 ]; then
          find_args+=(-o)
        fi
        find_args+=(-name "''${patterns[$i]}")
      done

      raw="$(
        find "$ROOT" -type d \( "''${find_args[@]}" \) -prune -print0 2>/dev/null \
          | xargs -0 -r du -s --block-size=1 2>/dev/null
      )"

      if [ -z "$raw" ]; then
        printf 'no matching cache directories found under %s\n' "$ROOT"
        exit 0
      fi

      human_awk='
        function human(b,   u, s, i) {
          u = "BKMGT"; s = b; i = 1
          while (s >= 1024 && i < 5) { s /= 1024; i++ }
          return (i == 1) ? sprintf("%dB", s) : sprintf("%.1f%s", s, substr(u, i, 1))
        }
      '

      if [ "$BY_REPO" = 1 ]; then
        result="$(
          printf '%s\n' "$raw" | awk -F'\t' -v root="$ROOT" '
            BEGIN { OFS = "\t" }
            {
              rel = substr($2, length(root) + 2)
              n = split(rel, parts, "/")
              repo = (n >= 3) ? parts[1] "/" parts[2] "/" parts[3] : rel
              sizes[repo] += $1
              counts[repo] += 1
            }
            END { for (r in sizes) print sizes[r], counts[r], r }
          ' | sort -rn | awk -F'\t' "$human_awk"'
            { printf "%s\t%s\t(%d dirs)\n", human($1), $3, $2 }
          '
        )"
      else
        result="$(
          printf '%s\n' "$raw" | sort -rn | awk -F'\t' "$human_awk"'
            { printf "%s\t%s\n", human($1), $2 }
          '
        )"
      fi

      if [ -n "$N" ]; then
        printf '%s\n' "$result" | head -n "$N"
      else
        printf '%s\n' "$result"
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
