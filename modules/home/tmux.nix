{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.takoeight0821.programs.tmux;

  tmux-center-focus = pkgs.writeShellApplication {
    name = "tmux-center-focus";
    runtimeInputs = [ pkgs.tmux ];
    text = ''
      set -euo pipefail

      get_opt() { tmux show-option -qv "$1" 2>/dev/null || echo ""; }
      set_opt() { tmux set-option -q "$1" "$2"; }

      acquire_lock() {
        local session_id
        session_id="$(tmux display-message -p '#{session_id}' | tr -d '$')"
        local channel="cf-lock-''${session_id}"
        tmux wait-for -L "$channel"
        trap 'tmux wait-for -U "'"$channel"'"' EXIT
      }

      scrub_list() {
        local cf_list cf_index
        cf_list="$(get_opt @cf_list)"
        cf_index="$(get_opt @cf_index)"

        if [ -z "$cf_list" ]; then
          return
        fi

        local alive
        alive="$(tmux list-panes -s -F '#{pane_id}' | tr '\n' ' ')"

        local new_list=""
        local removed_before_index=0
        local i=0
        for pane_id in $cf_list; do
          if echo " $alive " | grep -q " $pane_id "; then
            if [ -n "$new_list" ]; then
              new_list="$new_list $pane_id"
            else
              new_list="$pane_id"
            fi
          else
            if [ "$i" -lt "''${cf_index:-0}" ]; then
              removed_before_index=$((removed_before_index + 1))
            fi
          fi
          i=$((i + 1))
        done

        local new_index=$(( ''${cf_index:-0} - removed_before_index ))
        local count
        count="$(echo "$new_list" | wc -w | tr -d ' ')"

        if [ "$count" -eq 0 ]; then
          new_index=0
        elif [ "$new_index" -ge "$count" ]; then
          new_index=$((count - 1))
        elif [ "$new_index" -lt 0 ]; then
          new_index=0
        fi

        set_opt @cf_list "$new_list"
        set_opt @cf_index "$new_index"
      }

      get_visible_indices() {
        local cf_list cf_index
        cf_list="$(get_opt @cf_list)"
        cf_index="$(get_opt @cf_index)"
        local total
        total="$(echo "$cf_list" | wc -w | tr -d ' ')"

        if [ "$total" -eq 0 ]; then
          echo ""
          return
        fi

        if [ "$total" -eq 1 ]; then
          echo "$cf_index"
          return
        fi

        if [ "$total" -eq 2 ]; then
          echo "0 1"
          return
        fi

        local left=$(( (cf_index - 1 + total) % total ))
        local right=$(( (cf_index + 1) % total ))
        echo "$left $cf_index $right"
      }

      nth_pane() {
        local cf_list="$1"
        local n="$2"
        echo "$cf_list" | tr ' ' '\n' | sed -n "$((n + 1))p"
      }

      apply_layout() {
        local cf_list cf_index cf_window
        cf_list="$(get_opt @cf_list)"
        cf_index="$(get_opt @cf_index)"
        cf_window="$(get_opt @cf_window)"

        local total
        total="$(echo "$cf_list" | wc -w | tr -d ' ')"

        if [ "$total" -eq 0 ]; then
          return
        fi

        local visible_indices
        visible_indices="$(get_visible_indices)"

        local visible_panes=""
        for idx in $visible_indices; do
          local p
          p="$(nth_pane "$cf_list" "$idx")"
          if [ -n "$visible_panes" ]; then
            visible_panes="$visible_panes $p"
          else
            visible_panes="$p"
          fi
        done

        local panes_in_window
        panes_in_window="$(tmux list-panes -t "$cf_window" -F '#{pane_id}' | tr '\n' ' ')"

        for p in $panes_in_window; do
          if ! echo " $visible_panes " | grep -q " $p "; then
            if [ "$(tmux list-panes -t "$cf_window" | wc -l | tr -d ' ')" -gt 1 ]; then
              tmux break-pane -d -s "$p"
            fi
          fi
        done

        local first_visible
        first_visible="$(echo "$visible_panes" | awk '{print $1}')"

        local in_window
        in_window="$(tmux list-panes -t "$cf_window" -F '#{pane_id}' | tr '\n' ' ')"

        if ! echo " $in_window " | grep -q " $first_visible "; then
          local anchor
          anchor="$(tmux list-panes -t "$cf_window" -F '#{pane_id}' | head -1)"
          tmux join-pane -hb -s "$first_visible" -t "$anchor"
          in_window="$(tmux list-panes -t "$cf_window" -F '#{pane_id}' | tr '\n' ' ')"
          for p in $in_window; do
            if [ "$p" != "$first_visible" ] && ! echo " $visible_panes " | grep -q " $p "; then
              if [ "$(tmux list-panes -t "$cf_window" | wc -l | tr -d ' ')" -gt 1 ]; then
                tmux break-pane -d -s "$p"
              fi
            fi
          done
        fi

        local prev="$first_visible"
        local first=true
        for p in $visible_panes; do
          if $first; then
            first=false
            continue
          fi
          local cur_in_window
          cur_in_window="$(tmux list-panes -t "$cf_window" -F '#{pane_id}' | tr '\n' ' ')"
          if echo " $cur_in_window " | grep -q " $p "; then
            if [ "$(tmux list-panes -t "$cf_window" | wc -l | tr -d ' ')" -gt 1 ]; then
              tmux break-pane -d -s "$p"
            fi
          fi
          tmux join-pane -h -s "$p" -t "$prev"
          prev="$p"
        done

        local visible_count
        visible_count="$(echo "$visible_panes" | wc -w | tr -d ' ')"

        local focus_pane
        focus_pane="$(nth_pane "$cf_list" "$cf_index")"

        case "$visible_count" in
          1)
            ;;
          2)
            local first_p
            first_p="$(echo "$visible_panes" | awk '{print $1}')"
            if [ "$first_p" = "$focus_pane" ]; then
              tmux resize-pane -t "$first_p" -x 70%
            else
              tmux resize-pane -t "$first_p" -x 30%
            fi
            ;;
          3)
            local left_p center_p
            left_p="$(echo "$visible_panes" | awk '{print $1}')"
            center_p="$(echo "$visible_panes" | awk '{print $2}')"
            tmux resize-pane -t "$left_p" -x 15%
            tmux resize-pane -t "$center_p" -x 70%
            ;;
        esac

        tmux select-pane -t "$focus_pane"
      }

      cmd_init() {
        local window_id pane_id
        window_id="$(tmux display-message -p '#{window_id}')"
        pane_id="$(tmux display-message -p '#{pane_id}')"

        set_opt @cf_window "$window_id"
        set_opt @cf_list "$pane_id"
        set_opt @cf_index "0"

        tmux display-message "Center-focus mode initialized"
      }

      cmd_new() {
        scrub_list

        local cf_list cf_index cf_window
        cf_list="$(get_opt @cf_list)"
        cf_index="$(get_opt @cf_index)"
        cf_window="$(get_opt @cf_window)"

        if [ -z "$cf_window" ]; then
          tmux display-message "Center-focus not initialized. Press M-i first."
          return 1
        fi

        local focus_pane
        focus_pane="$(nth_pane "$cf_list" "$cf_index")"
        local new_pane
        new_pane="$(tmux split-window -h -d -t "$focus_pane" -P -F '#{pane_id}')"

        local new_list=""
        local i=0
        for p in $cf_list; do
          if [ -n "$new_list" ]; then
            new_list="$new_list $p"
          else
            new_list="$p"
          fi
          if [ "$i" -eq "$cf_index" ]; then
            new_list="$new_list $new_pane"
          fi
          i=$((i + 1))
        done

        set_opt @cf_list "$new_list"
        set_opt @cf_index "$((cf_index + 1))"

        apply_layout
      }

      cmd_left() {
        scrub_list

        local cf_list cf_index cf_window
        cf_list="$(get_opt @cf_list)"
        cf_index="$(get_opt @cf_index)"
        cf_window="$(get_opt @cf_window)"

        if [ -z "$cf_window" ]; then
          tmux display-message "Center-focus not initialized. Press M-i first."
          return 1
        fi

        local total
        total="$(echo "$cf_list" | wc -w | tr -d ' ')"

        local new_index=$(( (cf_index - 1 + total) % total ))
        set_opt @cf_index "$new_index"
        apply_layout
      }

      cmd_right() {
        scrub_list

        local cf_list cf_index cf_window
        cf_list="$(get_opt @cf_list)"
        cf_index="$(get_opt @cf_index)"
        cf_window="$(get_opt @cf_window)"

        if [ -z "$cf_window" ]; then
          tmux display-message "Center-focus not initialized. Press M-i first."
          return 1
        fi

        local total
        total="$(echo "$cf_list" | wc -w | tr -d ' ')"

        local new_index=$(( (cf_index + 1) % total ))
        set_opt @cf_index "$new_index"
        apply_layout
      }

      cmd_close() {
        scrub_list

        local cf_list cf_index cf_window
        cf_list="$(get_opt @cf_list)"
        cf_index="$(get_opt @cf_index)"
        cf_window="$(get_opt @cf_window)"

        if [ -z "$cf_window" ]; then
          tmux display-message "Center-focus not initialized. Press M-i first."
          return 1
        fi

        local total
        total="$(echo "$cf_list" | wc -w | tr -d ' ')"

        if [ "$total" -le 1 ]; then
          tmux display-message "Cannot close the last pane"
          return 0
        fi

        local focus_pane
        focus_pane="$(nth_pane "$cf_list" "$cf_index")"

        local new_list=""
        local i=0
        for p in $cf_list; do
          if [ "$i" -ne "$cf_index" ]; then
            if [ -n "$new_list" ]; then
              new_list="$new_list $p"
            else
              new_list="$p"
            fi
          fi
          i=$((i + 1))
        done

        local new_count
        new_count="$(echo "$new_list" | wc -w | tr -d ' ')"
        local new_index="$cf_index"
        if [ "$new_index" -ge "$new_count" ]; then
          new_index=$((new_count - 1))
        fi

        set_opt @cf_list "$new_list"
        set_opt @cf_index "$new_index"

        local next_focus
        next_focus="$(nth_pane "$new_list" "$new_index")"
        local in_window
        in_window="$(tmux list-panes -t "$cf_window" -F '#{pane_id}' | tr '\n' ' ')"
        if ! echo " $in_window " | grep -q " $next_focus "; then
          tmux join-pane -h -s "$next_focus" -t "$cf_window"
        fi

        tmux kill-pane -t "$focus_pane"

        apply_layout
      }

      cmd_refresh() {
        scrub_list
        apply_layout
      }

      main() {
        acquire_lock

        case "''${1:-}" in
          init)    cmd_init ;;
          new)     cmd_new ;;
          left)    cmd_left ;;
          right)   cmd_right ;;
          close)   cmd_close ;;
          refresh) cmd_refresh ;;
          *)
            echo "Usage: tmux-center-focus {init|new|left|right|close|refresh}" >&2
            exit 1
            ;;
        esac
      }

      main "$@"
    '';
  };
in
{
  options.takoeight0821.programs.tmux = {
    enable = lib.mkEnableOption "tmux configuration";
    centerFocus = {
      enable = lib.mkEnableOption "center-focus carousel pane manager";
      keybindings = {
        init = lib.mkOption {
          type = lib.types.str;
          default = "M-i";
          description = "Key binding to initialize center-focus mode";
        };
        left = lib.mkOption {
          type = lib.types.str;
          default = "M-h";
          description = "Key binding to navigate left";
        };
        right = lib.mkOption {
          type = lib.types.str;
          default = "M-l";
          description = "Key binding to navigate right";
        };
        new = lib.mkOption {
          type = lib.types.str;
          default = "M-n";
          description = "Key binding to create new pane";
        };
        close = lib.mkOption {
          type = lib.types.str;
          default = "M-w";
          description = "Key binding to close focused pane";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.tmux = {
          enable = true;
          terminal = "tmux-256color";
          mouse = true;
          keyMode = "vi";
          baseIndex = 1;
          escapeTime = 0;
          historyLimit = 50000;
          plugins = with pkgs.tmuxPlugins; [
            sensible
            {
              plugin = resurrect;
              extraConfig = "set -g @resurrect-strategy-nvim 'session'";
            }
            {
              plugin = continuum;
              extraConfig = ''
                set -g @continuum-restore 'on'
                set -g @continuum-save-interval '10'
              '';
            }
          ];
          extraConfig = ''
            set -as terminal-features "xterm-256color:RGB"
            set -as terminal-features "xterm-ghostty:RGB:hyperlinks"
            set -g allow-passthrough on
            set -g focus-events on
            set -g set-clipboard on

            bind h select-pane -L
            bind j select-pane -D
            bind k select-pane -U
            bind l select-pane -R
          '';
        };

        home.activation.tmuxSocketDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "${config.home.homeDirectory}/.tmux/sockets"
          chmod 700 "${config.home.homeDirectory}/.tmux/sockets"
        '';
      }
      (lib.mkIf cfg.centerFocus.enable {
        home.packages = [ tmux-center-focus ];
        programs.tmux.extraConfig = ''
          bind -n ${cfg.centerFocus.keybindings.init} run-shell "tmux-center-focus init"
          bind -n ${cfg.centerFocus.keybindings.left} run-shell "tmux-center-focus left"
          bind -n ${cfg.centerFocus.keybindings.right} run-shell "tmux-center-focus right"
          bind -n ${cfg.centerFocus.keybindings.new} run-shell "tmux-center-focus new"
          bind -n ${cfg.centerFocus.keybindings.close} run-shell "tmux-center-focus close"
        '';
      })
    ]
  );
}
