{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.takoeight0821.programs.ghq-cleanup;

  ghq-cleanup = pkgs.writeShellApplication {
    name = "ghq-cleanup";
    runtimeInputs = with pkgs; [
      coreutils
      git
      ghq
      gawk
    ];
    text = ''
      set -euo pipefail

      usage() {
        cat <<'EOF'
      Usage: ghq-cleanup [-n DAYS] [-r ROOT] [-d] [-h]

      List ghq-managed repositories whose last commit is older than DAYS and
      optionally delete them. Defaults to dry-run; pass -d to actually delete.

      Options:
        -n DAYS   Threshold in days since last commit (default: 180)
        -r ROOT   Use ROOT instead of `ghq root`
        -d        Delete candidates after a single y/N confirmation
        -h        Show this help

      Output columns:
        AGE      Days since HEAD committer date, or filesystem mtime for
                 non-git directories.
        SIZE     On-disk size of the repository.
        FLAGS    D=uncommitted changes, U=unpushed (no upstream, or ahead),
                 -=clean, ?=not a git repo.
        PATH     Repository path.
      EOF
      }

      THRESHOLD_DAYS=180
      ROOT=""
      DELETE=0

      while getopts ":n:r:dh" opt; do
        case "$opt" in
          n) THRESHOLD_DAYS="$OPTARG" ;;
          r) ROOT="$OPTARG" ;;
          d) DELETE=1 ;;
          h) usage; exit 0 ;;
          :) printf 'error: -%s requires an argument\n' "$OPTARG" >&2; exit 1 ;;
          \?) printf 'error: unknown option -%s\n' "$OPTARG" >&2; usage >&2; exit 1 ;;
        esac
      done

      case "$THRESHOLD_DAYS" in
        "" | *[!0-9]*)
          printf 'error: -n must be a non-negative integer, got: %s\n' "$THRESHOLD_DAYS" >&2
          exit 1
          ;;
      esac

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

      NOW="$(date +%s)"
      THRESHOLD_SEC=$((THRESHOLD_DAYS * 86400))

      # Collect rows: AGE_DAYS \t SIZE_BYTES \t FLAGS \t PATH
      raw="$(
        ghq list -p 2>/dev/null | while IFS= read -r repo; do
          [ -d "$repo" ] || continue

          last_ts=""
          flags="?"

          if git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
            last_ts="$(git -C "$repo" log -1 --format=%ct HEAD 2>/dev/null || true)"

            dirty=0
            if [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ]; then
              dirty=1
            fi

            unpushed=1
            if git -C "$repo" rev-parse '@{u}' >/dev/null 2>&1; then
              ahead="$(git -C "$repo" rev-list '@{u}..HEAD' --count 2>/dev/null || echo 0)"
              if [ "$ahead" -eq 0 ]; then
                unpushed=0
              fi
            fi

            flags=""
            [ "$dirty" -eq 1 ] && flags="''${flags}D"
            [ "$unpushed" -eq 1 ] && flags="''${flags}U"
            [ -z "$flags" ] && flags="-"
          fi

          if [ -z "$last_ts" ]; then
            last_ts="$(stat -c %Y "$repo" 2>/dev/null || echo 0)"
          fi

          age_sec=$((NOW - last_ts))
          if [ "$age_sec" -lt "$THRESHOLD_SEC" ]; then
            continue
          fi
          age_days=$((age_sec / 86400))

          size_bytes="$(du -s --block-size=1 "$repo" 2>/dev/null | awk '{print $1; exit}')"
          [ -n "$size_bytes" ] || size_bytes=0

          printf '%s\t%s\t%s\t%s\n' "$age_days" "$size_bytes" "$flags" "$repo"
        done
      )"

      if [ -z "$raw" ]; then
        printf 'no repositories older than %s days under %s\n' "$THRESHOLD_DAYS" "$ROOT"
        exit 0
      fi

      human_awk='
        function human(b,   u, s, i) {
          u = "BKMGT"; s = b; i = 1
          while (s >= 1024 && i < 5) { s /= 1024; i++ }
          return (i == 1) ? sprintf("%dB", s) : sprintf("%.1f%s", s, substr(u, i, 1))
        }
      '

      sorted="$(printf '%s\n' "$raw" | sort -t"$(printf '\t')" -k1,1nr)"

      printf 'AGE\tSIZE\tFLAGS\tPATH\n'
      printf '%s\n' "$sorted" | awk -F'\t' "$human_awk"'
        { printf "%sd\t%s\t%s\t%s\n", $1, human($2), $3, $4 }
      '

      total_bytes="$(printf '%s\n' "$raw" | awk -F'\t' '{s += $2} END { print s+0 }')"
      total_human="$(printf '%s\n' "$total_bytes" | awk "$human_awk"'{ print human($1) }')"
      count="$(printf '%s\n' "$raw" | awk 'END { print NR }')"
      dirty_count="$(printf '%s\n' "$raw" | awk -F'\t' '$3 ~ /[DU]/ {c++} END { print c+0 }')"

      if [ "$dirty_count" -gt 0 ]; then
        printf '\n%s repositories, %s total (%s with D/U flags)\n' "$count" "$total_human" "$dirty_count"
      else
        printf '\n%s repositories, %s total\n' "$count" "$total_human"
      fi

      if [ "$DELETE" -ne 1 ]; then
        printf 'Run with -d to delete.\n'
        exit 0
      fi

      printf 'Delete %s repositories (%s)? [y/N] ' "$count" "$total_human"
      answer=""
      read -r answer || true
      case "$answer" in
        [yY] | [yY][eE][sS]) ;;
        *) printf 'aborted.\n'; exit 0 ;;
      esac

      printf '%s\n' "$raw" | awk -F'\t' '{print $4}' | while IFS= read -r repo; do
        printf 'removing %s\n' "$repo"
        rm -rf -- "$repo"
      done
      printf 'done.\n'
    '';
  };
in
{
  options.takoeight0821.programs.ghq-cleanup = {
    enable = lib.mkEnableOption "ghq-cleanup (delete long-unedited ghq repositories)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ ghq-cleanup ];
  };
}
