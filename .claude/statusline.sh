#!/bin/bash
# Combined status line for Claude Code
# Features: context bar, git details, time, last prompt, ANSI + emoji

# Configuration
SEP_STYLE="║"              # Separator style: │ ┃ ║ ⋮ ╎ ┆

# Read JSON input
input=$(cat)

# Extract data using jq
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
output_style=$(echo "$input" | jq -r '.output_style.name // ""')
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')

# Session stats
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
tokens_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
tokens_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# ANSI Colors
RESET="\033[0m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
MAGENTA="\033[35m"
GRAY="\033[90m"
WHITE="\033[37m"
GREEN="\033[32m"
DIM="\033[2m"

# Separator (uses configured style)
SEP="${DIM}${SEP_STYLE}${RESET}"

# Format duration from milliseconds to human readable
format_duration() {
  local ms=$1
  local seconds=$((ms / 1000))
  local minutes=$((seconds / 60))
  local hours=$((minutes / 60))
  minutes=$((minutes % 60))

  if [ "$hours" -gt 0 ]; then
    printf "%dh%dm" "$hours" "$minutes"
  elif [ "$minutes" -gt 0 ]; then
    printf "%dm" "$minutes"
  else
    printf "%ds" "$seconds"
  fi
}

# Format lines changed
format_lines_changed() {
  local added=$1
  local removed=$2

  if [ "$added" -eq 0 ] && [ "$removed" -eq 0 ]; then
    echo ""
  else
    printf "${GREEN}+%d${RESET} ${RED}-%d${RESET}" "$added" "$removed"
  fi
}

# Format token count with k/M suffix
format_tokens() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then
    awk "BEGIN {printf \"%.1fM\", $n/1000000}"
  elif [ "$n" -ge 1000 ]; then
    awk "BEGIN {printf \"%.1fk\", $n/1000}"
  else
    printf "%d" "$n"
  fi
}

# Get terminal width from JSON input if available, otherwise use generous default
# Claude Code doesn't reliably pass TTY info, so we use a large default
json_width=$(echo "$input" | jq -r '.terminal_width // .term_width // .width // 0' 2>/dev/null)
if [ -n "$json_width" ] && [ "$json_width" -gt 100 ] 2>/dev/null; then
  term_width=$json_width
elif [ -n "$COLUMNS" ] && [ "$COLUMNS" -gt 100 ] 2>/dev/null; then
  term_width=$COLUMNS
else
  # Default to 200 - better to show more than truncate too much
  term_width=200
fi

# Get directory display name
if [ -n "$cwd" ]; then
  if [ "$cwd" = "$HOME" ]; then
    dir_display="~"
  else
    dir_display=$(basename "$cwd")
  fi
else
  dir_display="?"
fi

# Detect worktree name from path pattern /trees/<name>/
worktree_name=""
if [[ "$cwd" =~ /trees/([^/]+)(/|$) ]]; then
  worktree_name="${BASH_REMATCH[1]}"
fi

# Get git info (branch, dirty, ahead, modified count)
git_info=""
git_info_plain=""
# NOTE: git branch names can be long, so let's just excl for now
# if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
#   branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || echo "detached")
#
#   # Check if dirty (staged or unstaged changes)
#   dirty=""
#   if ! git -C "$cwd" diff --quiet 2>/dev/null || ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
#     dirty="*"
#   fi
#
#   # Check commits ahead of upstream
#   ahead_marker=""
#   ahead_plain=""
#   ahead_output=$(git -C "$cwd" rev-list @{u}..HEAD 2>/dev/null)
#   if [ -n "$ahead_output" ]; then
#     ahead=$(echo "$ahead_output" | wc -l | tr -d ' ')
#     ahead_marker=" ${GREEN}↑${ahead}${RESET}"
#     ahead_plain=" ↑${ahead}"
#   fi
#
#   # Count modified files (staged + unstaged + untracked)
#   mod_count=$(git -C "$cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
#   mod_marker=""
#   mod_plain=""
#   if [ "$mod_count" -gt 0 ]; then
#     mod_marker=" ${GRAY}${mod_count}f${RESET}"
#     mod_plain=" ${mod_count}f"
#   fi
#
#   git_info=$(printf "${YELLOW}%s${RESET}${RED}%s${RESET}%s%s" "$branch" "$dirty" "$ahead_marker" "$mod_marker")
#   git_info_plain="${branch}${dirty}${ahead_plain}${mod_plain}"
# fi

# Format context: show % used of total context window (matches /context)
# Uses true color (24-bit ANSI) gradient: green → yellow → red
context_info=""
context_info_plain=""

pct_used=$used_pct
[ "$pct_used" -lt 0 ] && pct_used=0
[ "$pct_used" -gt 100 ] && pct_used=100

filled=$((pct_used / 10))

# Build gradient bar with true color
# Gradient: green(0,255,0) → yellow(255,255,0) → red(255,0,0)
bar=""
bar_plain=""
for ((i=0; i<10; i++)); do
  if [ $i -lt $filled ]; then
    # Calculate gradient color for this position
    if [ $i -lt 5 ]; then
      # Green to yellow: increase red
      r=$((i * 51))
      g=255
    else
      # Yellow to red: decrease green
      r=255
      g=$((255 - (i - 4) * 51))
    fi
    # True color ANSI: \033[38;2;R;G;Bm
    bar+="\033[38;2;${r};${g};0m▰"
    bar_plain+="▰"
  else
    # Empty segment in gray
    bar+="\033[38;2;100;100;100m▱"
    bar_plain+="▱"
  fi
done

# Append $ cost to context bar if non-zero
cost_str=""
cost_str_plain=""
if awk "BEGIN {exit !($cost_usd > 0)}" 2>/dev/null; then
  cost_str=$(awk "BEGIN {printf \" ${GREEN}\$%.2f${RESET}\", $cost_usd}" 2>/dev/null || printf "")
  cost_str_plain=$(awk "BEGIN {printf \" \$%.2f\", $cost_usd}")
fi

context_info=$(printf "⟨%b${RESET}⟩ %d%%%b" "$bar" "$pct_used" "$cost_str")
context_info_plain="⟨${bar_plain}⟩ ${pct_used}%${cost_str_plain}"

# Format model + effort
model_short=$(echo "$model" | sed 's/^Claude //' | tr '[:upper:]' '[:lower:]')
model_info=""
model_info_plain=""
if [ -n "$model_short" ] && [ "$model_short" != "unknown" ]; then
  if [ -n "$output_style" ] && [ "$output_style" != "default" ] && [ "$output_style" != "null" ]; then
    model_info=$(printf "${MAGENTA}%s${RESET} ${DIM}%s${RESET}" "$model_short" "$output_style")
    model_info_plain="${model_short} ${output_style}"
  else
    model_info=$(printf "${MAGENTA}%s${RESET}" "$model_short")
    model_info_plain="${model_short}"
  fi
fi

# Current time (12-hour format with am/pm)
time_now=$(date '+%l:%M%P' | tr -d ' ')

# Build left side: dir ║ git ║ lines ║ context ║ duration ║ time
# Grouping: WHERE (dir, git) → WHAT (lines) → STATUS (context, duration, time)
# Minimalist version: no emojis, clean separators
left_output="${DIM}in${RESET} ${CYAN}${dir_display}${RESET}"
left_width=$((4 + ${#dir_display}))  # └──(3) + space(1) + dir

# WHERE: Worktree name (if in a worktree)
if [ -n "$worktree_name" ]; then
  left_output="${left_output} ${GRAY}[${worktree_name}]${RESET}"
  left_width=$((left_width + 2 + ${#worktree_name} + 1))  # space + [ + name + ]
fi

# WHERE: Git info
if [ -n "$git_info" ]; then
  left_output="${left_output} ${SEP} ${git_info}"
  git_ascii_len=${#branch}
  [ -n "$dirty" ] && git_ascii_len=$((git_ascii_len + 1))
  [ -n "$ahead_plain" ] && git_ascii_len=$((git_ascii_len + 1 + ${#ahead}))
  [ -n "$mod_plain" ] && git_ascii_len=$((git_ascii_len + 2 + ${#mod_count}))
  left_width=$((left_width + 3 + 2 + 1 + git_ascii_len))
fi

# WHAT: Lines changed
lines_info=$(format_lines_changed "$lines_added" "$lines_removed")
if [ -n "$lines_info" ]; then
  left_output="${left_output} ${SEP} ${lines_info}"
  added_len=${#lines_added}
  removed_len=${#lines_removed}
  left_width=$((left_width + 3 + 1 + added_len + 1 + 1 + removed_len))
fi

# WHAT: Token usage (in ↑ / out ↓)
if [ "$tokens_in" -gt 0 ] 2>/dev/null || [ "$tokens_out" -gt 0 ] 2>/dev/null; then
  tok_in_str=$(format_tokens "$tokens_in")
  tok_out_str=$(format_tokens "$tokens_out")
  left_output="${left_output} ${SEP} ${GRAY}↑${tok_in_str} ↓${tok_out_str}${RESET}"
  left_width=$((left_width + 3 + 1 + ${#tok_in_str} + 2 + ${#tok_out_str}))
fi

# STATUS: Context bar (includes $ cost)
if [ -n "$context_info" ]; then
  left_output="${left_output} ${SEP} ${context_info}"
  pct_len=${#pct_used}
  cost_plain_len=${#cost_str_plain}
  context_display_width=$((1 + 10 + 1 + 1 + pct_len + 1 + cost_plain_len))  # ⟨ + bar + ⟩ + space + pct + % + cost
  left_width=$((left_width + 3 + context_display_width))
fi

# STATUS: Model + effort
if [ -n "$model_info" ]; then
  left_output="${left_output} ${SEP} ${model_info}"
  left_width=$((left_width + 3 + ${#model_info_plain}))
fi

# STATUS: Session duration
if [ "$duration_ms" -gt 0 ] 2>/dev/null; then
  duration_str=$(format_duration "$duration_ms")
  left_output="${left_output} ${SEP} ${CYAN}${duration_str}${RESET}"
  left_width=$((left_width + 3 + ${#duration_str}))
fi

# STATUS: Clock
left_output="${left_output} ${SEP} ${GRAY}${time_now}${RESET}"
left_width=$((left_width + 3 + 5))  # HH:MM = 5 chars

# Add last prompt with prompt arrow separator
left_output="${left_output} ${CYAN}❯${RESET} ${GRAY}"
left_width=$((left_width + 3))

# Calculate available width for prompt text
available=$((term_width - left_width))
[ "$available" -lt 10 ] && available=10

# Extract last prompt from JSONL transcript
prompt_display=""
if [ -f "$transcript_path" ]; then
  last_prompt=$(grep '"type":"user"' "$transcript_path" 2>/dev/null | grep -v '"tool_use_id"' | tail -1 | jq -r '.message.content // empty' 2>/dev/null)
  if [ -n "$last_prompt" ] && [ "$last_prompt" != "null" ]; then
    prompt_text=$(echo "$last_prompt" | tr '\n\r' ' ' | sed 's/[[:space:]]\+/ /g' | sed 's/^ *//;s/ *$//')
    if [ ${#prompt_text} -gt "$available" ]; then
      prompt_display="${prompt_text:0:$((available - 3))}..."
    else
      prompt_display="$prompt_text"
    fi
  fi
fi

# Output final statusline
printf "%b%s${RESET}\n" "$left_output" "$prompt_display"
