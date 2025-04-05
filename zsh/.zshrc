# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"
# ZSH_THEME="norm"
ZSH_THEME="agnoster"
# ZSH_THEME="philips"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="yyyy-mm-dd"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	colorize
	dotenv
	fzf-tab # custom (aka not included in oh-my-zsh's default list) plugin
	)

source $ZSH/oh-my-zsh.sh

# ------------------------------------------------------------------------------
# User configuration after sourcing oh-my-zsh
# ------------------------------------------------------------------------------

alias pip=pip3

# commenting out for now. Seems to cause terminal to freeze when arrowing up/down through suggestions
# source $(brew --prefix)/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

alias gs="git status"


# # Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
# fuzzy cd

# simple sd below. But it errors out on Library folder
# alias sd="cd ~/code && cd \$(find . -type d -maxdepth 3 | fzf)"
# exclude Library folder & its sub folders
alias sd="cd ~ && cd \$(find . -path ./Library -prune -o -path ./.Trash -prune -o -type d -maxdepth 4 -print | fzf)"

alias sf="cd ~/code && nvim \$(find . -type f | fzf)"

# node.js & nvm config
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# local scripts setup
export LOCAL_SCRIPTS_DIR="$HOME/code/dotfiles/scripts"
# alias jarvis="python $LOCAL_SCRIPTS_DIR/ask_jarvis/ask_jarvis.py"
# NOTE: using the global pyenv version which should have the required depenencies, instead of the possible virtual env version which might not
alias jarvis="$HOME/.pyenv/shims/python $LOCAL_SCRIPTS_DIR/ask_jarvis/ask_jarvis.py"

export wut() {
  echo "$@" > $HOME/.jarvis/wut_command.log  # Log the command
  "$@" > >(tee -a $HOME/.jarvis/wut_command.log) 2> >(tee -a $HOME/.jarvis/wut_command.log >&2) # Log the output from the command
}

# Check for open ai key, update if expired
if ! $(openai_key check); then
  openai_key update
fi
export OPENAI_API_KEY=$(openai_key cat) # NOTE: this is overriding it in .zshenv, which we're okay with because it needs to be consistently refreshed
alias pls="openai_key"

# Aider config
export AIDER_DARK_MODE=true
alias aider_shop="aider --model openai/anthropic:claude-3-5-sonnet-20241022 --watch-files"

# NOTE: commenting out rbenv setup now, as it's incompatible with current co. tooling
# Ruby config
# eval "$(rbenv init - zsh)"

# NOTE: custom right prompt
PROMPT_STATUS="%F{red}%(?..[%?])%f" # Show exit status of last command in red, if non-zero
TIME_24HR="%F{241}%B[%*]%b%f" # 24hr clock in gray
RPROMPT="${PROMPT_STATUS}${TIME_24HR}"

# NOTE: below are auto added lines
[[ -x /opt/homebrew/bin/brew ]] && eval $(/opt/homebrew/bin/brew shellenv)

[ -f /opt/dev/dev.sh ] && source /opt/dev/dev.sh

[[ -f /opt/dev/sh/chruby/chruby.sh ]] && { type chruby >/dev/null 2>&1 || chruby () { source /opt/dev/sh/chruby/chruby.sh; chruby "$@"; } }
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
