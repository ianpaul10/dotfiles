# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="wot_in_tarnation" # custom theme

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

HIST_STAMPS="yyyy-mm-dd"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	colorize
	dotenv
	fzf-tab # custom (aka not included in oh-my-zsh's default list) plugin
	shrink-path
	)

source $ZSH/oh-my-zsh.sh

# ------------------------------------------------------------------------------
# User configuration after sourcing oh-my-zsh
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Session logging - auto-logs all `dev` commands to SQLite
# ------------------------------------------------------------------------------
SESSION_LOG_DB="$HOME/.session_logs/commands.db"
mkdir -p "$(dirname "$SESSION_LOG_DB")"

# Initialize db/table if needed
sqlite3 "$SESSION_LOG_DB" "CREATE TABLE IF NOT EXISTS commands (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts TEXT NOT NULL,
  cmd TEXT NOT NULL,
  output TEXT,
  exit_code INTEGER,
  duration_ms INTEGER
);" 2>/dev/null

dev() {
  local tmpfile=$(mktemp)
  local start_ts=$(date -Iseconds)
  local start_s=$SECONDS

  command dev "$@" 2>&1 | tee "$tmpfile"
  local exit_code=${pipestatus[1]}
  local duration_s=$((SECONDS - start_s))

  local cmd="dev $*"
  local output=$(cat "$tmpfile")

  # Escape single quotes for SQLite
  cmd="${cmd//\'/\'\'}"
  output="${output//\'/\'\'}"

  sqlite3 "$SESSION_LOG_DB" \
    "INSERT INTO commands (ts, cmd, output, exit_code, duration_ms) VALUES ('$start_ts', '$cmd', '$output', $exit_code, $((duration_s * 1000)));"

  rm "$tmpfile"
  return $exit_code
}

alias pip=pip3

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

alias gs="git status"
alias lmk="afplay /System/Library/Sounds/Submarine.aiff" # let me know
alias rip="dev down && dev reset --all -n . && dev vitess cleanup && dev yugabyte cleanup && dev up"
alias gtlgtm="gt modify -a && gt submit --stack --update-only"
alias scratch='cd ~/code/brain_dump/scratch && nvim $(date +%Y_%m_%d_%H%M%S).md'
alias devlog="$LOCAL_SCRIPTS_DIR/devlog"

# gron is cool -> https://github.com/tomnomnom/gron
alias norg="gron --ungron"
alias ungron="gron --ungron"

# # Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

max_depth=4
if $WORK_LAPPY; then
  max_depth=7 # long paths for whatever reason
fi

# search directories
alias sd="cd ~ && cd \$(find ./code ./src ./world ./.jarvis ./idontexist -path '*/.git' -prune -o -type d -maxdepth ${max_depth} -print | fzf)"
alias sf="cd ~/code && nvim \$(find . -type f | fzf)"

# node.js & nvm config
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# local scripts setup
export LOCAL_SCRIPTS_DIR="$HOME/code/dotfiles/scripts"
# NOTE: using the global pyenv version which should have the required depenencies, instead of the possible virtual env version which might not
alias jarvis="$HOME/.pyenv/shims/python $LOCAL_SCRIPTS_DIR/ask_jarvis/ask_jarvis.py"

export wut() {
  echo "$@" > $HOME/.jarvis/wut_command.log  # Log the command
  "$@" > >(tee -a $HOME/.jarvis/wut_command.log) 2> >(tee -a $HOME/.jarvis/wut_command.log >&2) # Log the output from the command
}

# note taking for geekbot/gokbeet
export gokbeet() {
  local message="$*"
  local filename="$(date +%Y_%m_%d).md"
  echo "$message" >> "$HOME/code/brain_dump/daily/$filename"
}

source $LOCAL_SCRIPTS_DIR/semantic_prompt_wrapper.sh

# Check for open ai key, update if expired
if $WORK_LAPPY; then
  if ! $(openai_key check); then
    openai_key update
  fi
  export OPENAI_API_KEY=$(openai_key cat) # NOTE: this is overriding it in .zshenv, which we're okay with because it needs to be consistently refreshed
  alias pls="openai_key"
fi

# Aider config
export AIDER_DARK_MODE=true
alias aider_shop="aider --model openai/anthropic:claude-3-5-sonnet-20241022 --watch-files --map-refresh manual --map-tokens 2048"

# Ruby config
if ! $WORK_LAPPY; then
  # NOTE: ignoring rbenv setup now, it's incompatible with current co. tooling
  eval "$(rbenv init - zsh)"
fi

# NOTE: below are auto added lines
[[ -x /opt/homebrew/bin/brew ]] && eval $(/opt/homebrew/bin/brew shellenv)

if $WORK_LAPPY; then
  [ -f /opt/dev/dev.sh ] && source /opt/dev/dev.sh
  [[ -f /opt/dev/sh/chruby/chruby.sh ]] && { type chruby >/dev/null 2>&1 || chruby () { source /opt/dev/sh/chruby/chruby.sh; chruby "$@"; } }
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
  eval "$(shadowenv init zsh 2> /dev/null)"
fi

# Added by tec agent
[[ -x /Users/ip_shopify/.local/state/tec/profiles/base/current/global/init ]] && eval "$(/Users/ip_shopify/.local/state/tec/profiles/base/current/global/init zsh)"

echo "🫡"
