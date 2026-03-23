#!/bin/bash
INPUT=$(cat)
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
MESSAGE=$(echo "$INPUT" | jq -r '.message // ""')

if [ -n "$MESSAGE" ]; then
  TEXT="$TITLE: $MESSAGE"
else
  TEXT="$TITLE"
fi

TEXT=$(echo "$TEXT" | tr -d '\n\r\a\033')

if [[ "$TERM_PROGRAM" == "tmux" || -n "$TMUX" ]]; then
  printf '\ePtmux;\e\e]9;%s\a\e\\' "$TEXT" > /dev/tty 2>/dev/null
else
  printf '\e]9;%s\e\\' "$TEXT" > /dev/tty 2>/dev/null
fi
