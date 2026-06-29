#!/bin/bash
# Single-file status line for Claude Code. No Node, no Nerd Font, no config.
# Reads session JSON on stdin, prints one colored line.
input=$(cat)

RESET=$'\033[0m'; DIM=$'\033[2m'
GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; MAGENTA=$'\033[35m'

# colorpct VALUE WARN CRIT -> green below WARN, yellow at WARN, red at CRIT
colorpct() {
  if   [ "$1" -ge "$3" ]; then printf '%s' "$RED"
  elif [ "$1" -ge "$2" ]; then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"; fi
}

model=$(echo "$input" | jq -r '.model.display_name // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')

cwd_full=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
cwd=""
[ -n "$cwd_full" ] && cwd=$(basename "$cwd_full")

# git branch + dirty marker, computed from the working dir
branch=""
if [ -n "$cwd_full" ]; then
  branch=$(git -C "$cwd_full" branch --show-current 2>/dev/null)
  if [ -n "$branch" ] && [ -n "$(git -C "$cwd_full" status --porcelain 2>/dev/null)" ]; then
    branch="${branch}*"
  fi
fi

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

added=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
removed=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

parts=()

if [ -n "$cwd" ]; then
  seg="$cwd"
  [ -n "$branch" ] && seg="$seg ${MAGENTA}(${branch})${RESET}"
  parts+=("$seg")
fi

if [ -n "$model" ]; then
  seg="$model"
  [ -n "$effort" ] && seg="$seg ${DIM}${effort}${RESET}"
  parts+=("$seg")
fi

if [ -n "$used_pct" ]; then
  ui=$(printf '%.0f' "$used_pct")
  parts+=("$(colorpct "$ui" 50 80)ctx:${ui}%${RESET}")
fi

if [ -n "$five_pct" ]; then
  f=$(printf '%.0f' "$five_pct")
  lbl="$(colorpct "$f" 70 90)5h:${f}%${RESET}"
  if [ -n "$five_resets_at" ]; then
    rt=$(date -r "$five_resets_at" +"%H:%M" 2>/dev/null)
    [ -n "$rt" ] && lbl="$lbl ${DIM}resets $rt${RESET}"
  fi
  parts+=("$lbl")
fi

if [ -n "$week_pct" ]; then
  w=$(printf '%.0f' "$week_pct")
  parts+=("$(colorpct "$w" 70 90)7d:${w}%${RESET}")
fi

if [ -n "$added" ] || [ -n "$removed" ]; then
  a=${added:-0}; r=${removed:-0}
  [ "$a" != "0" ] || [ "$r" != "0" ] && parts+=("${GREEN}+${a}${RESET}/${RED}-${r}${RESET}")
fi

[ -n "$cost" ] && parts+=("$(printf '$%.2f' "$cost")")

output=""
for part in "${parts[@]}"; do
  [ -n "$output" ] && output="$output ${DIM}|${RESET} $part" || output="$part"
done

printf '%s\n' "$output"
