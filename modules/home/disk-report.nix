{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.takoeight0821.programs.disk-report;

  disk-report = pkgs.writeShellApplication {
    name = "disk-report";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      set -euo pipefail

      usage() {
        cat <<'EOF'
      Usage: disk-report [subcommand] [args]

      Subcommands:
        all [PATH] [N=20]   Show df followed by du (default)
        df                  Filesystem overview
        du [PATH] [N=20]    Top N largest subdirs under PATH (default cwd, N=20)
        -h, --help          Show this help
      EOF
      }

      do_df() {
        printf '== Filesystem overview ==\n'
        df -h
      }

      do_du() {
        local path="''${1:-.}"
        local n="''${2:-20}"
        if [ ! -d "$path" ]; then
          printf 'error: not a directory: %s\n' "$path" >&2
          return 1
        fi
        case "$n" in
          "" | *[!0-9]*)
            printf 'error: N must be a positive integer, got: %s\n' "$n" >&2
            return 1
            ;;
        esac
        printf '== Top %s entries under %s ==\n' "$n" "$path"
        du -xhd 1 "$path" 2>/dev/null | sort -hr | head -n "$n"
      }

      main() {
        local cmd="''${1:-all}"
        if [ "$#" -gt 0 ]; then shift; fi
        case "$cmd" in
          -h | --help | help) usage ;;
          df) do_df ;;
          du) do_du "$@" ;;
          all)
            do_df
            printf '\n'
            do_du "$@"
            ;;
          *)
            printf 'unknown subcommand: %s\n' "$cmd" >&2
            usage >&2
            exit 1
            ;;
        esac
      }

      main "$@"
    '';
  };
in
{
  options.takoeight0821.programs.disk-report = {
    enable = lib.mkEnableOption "disk-report helper (df + top-N du wrapper)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ disk-report ];
  };
}
