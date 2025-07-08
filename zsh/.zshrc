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

echo "🫡"
