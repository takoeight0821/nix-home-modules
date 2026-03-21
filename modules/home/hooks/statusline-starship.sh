#!/bin/bash
# statusline-starship.sh - Claude Code status line generator
#
# Generates a colorized status line for Claude Code showing:
#   - Current directory (with ~ expansion)
#   - Git branch name (in magenta)
#   - Model name (in green)
#   - Context window usage percentage (in yellow)
#   - Rate limit usage: 5-hour and 7-day (in red, when available)
#
# Usage: Set as statusLine command in Claude Code settings.
#   Input: JSON from stdin with workspace, model, and context_window info
#   Output: ANSI-colored status line text to stdout
#
# Dependencies: jq, git

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir')
model=$(echo "$input" | jq -r '.model.display_name')

dir_display="${cwd/#$HOME/~}"

git_info=""
if git -C "$cwd" rev-parse --git-dir &>/dev/null; then
    branch=$(git -C "$cwd" -c core.useBuiltinFSMonitor=false -c core.untrackedCache=false branch --show-current 2>/dev/null || git -C "$cwd" -c core.useBuiltinFSMonitor=false -c core.untrackedCache=false rev-parse --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        git_info=" $(printf '\033[35m')on$(printf '\033[0m') $(printf '\033[35m')${branch}$(printf '\033[0m')"
    fi
fi

model_info=" $(printf '\033[32m')${model}$(printf '\033[0m')"

context_info=""
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
if [ -n "$used_pct" ]; then
    used_int=$(printf "%.0f" "$used_pct")
    remaining_int=$(printf "%.0f" "$remaining_pct")
    context_info=" $(printf '\033[33m')[ctx:${used_int}%]$(printf '\033[0m')"
fi

rate_info=""
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rate_parts=""
if [ -n "$five_pct" ]; then
    five_int=$(printf "%.0f" "$five_pct")
    rate_parts="5h:${five_int}%"
fi
if [ -n "$week_pct" ]; then
    week_int=$(printf "%.0f" "$week_pct")
    if [ -n "$rate_parts" ]; then
        rate_parts="${rate_parts} 7d:${week_int}%"
    else
        rate_parts="7d:${week_int}%"
    fi
fi
if [ -n "$rate_parts" ]; then
    rate_info=" $(printf '\033[31m')[${rate_parts}]$(printf '\033[0m')"
fi

printf "$(printf '\033[36m')%s$(printf '\033[0m')%s%s%s%s" "$dir_display" "$git_info" "$model_info" "$context_info""$rate_info"
