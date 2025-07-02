# inspired by af-magic
# also help from https://aamnah.com/notes/sysadmin/zsh-custom-theme-ultimate-guide/

# use extended color palette if available
if [[ $terminfo[colors] -ge 256 ]]; then
    turquoise="%F{81}"
    tangerine="%F{166}"
    orange="%F{214}"
    purple="%F{105}"
    violet="%F{135}"
    hotpink="%F{161}"
    limegreen="%F{118}"
    green="%F{078}"
    gray="%F{241}"
    blue="%F{032}"
    red="%F{red}"
else
    turquoise="%F{cyan}"
    tangerine="%F{yellow}"
    orange="%F{yellow}"
    purple="%F{magenta}"
    violet="%F{magenta}"
    hotpink="%F{red}"
    limegreen="%F{green}"
    green="%F{green}"
    gray="%F{white}"
    blue="%F{blue}"
    red="%F{red}"
fi

PR_RST="%f"

# git settings
ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY="%{$orange%}*${PR_RST}"
ZSH_THEME_GIT_PROMPT_SUFFIX="${PR_RST}"

ZSH_THEME_GIT_PROMPT_ADDED="%{$green%} ✈"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%} ✭"
ZSH_THEME_GIT_PROMPT_DELETED="%{$red%} ✗"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[blue]%} ➦"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[magenta]%} ✂"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$gray%} ✱"

# virtualenv settings
ZSH_THEME_VIRTUALENV_PREFIX=" $FG[075]["
ZSH_THEME_VIRTUALENV_SUFFIX="]%{$reset_color%}"

# primary prompt
# NOTE: if things get slow, swap $(shrink_path -f) with %~ or %c
PS1='%{$blue%}$(shrink_path -f) %{$turquoise%}$(git_prompt_info) %{$purple%}%(!.#.%%) ${PR_RST}'

# primary prompt when no git repo
if [ -z "$(git_current_branch)" ]; then 
PS1='%{$blue%}$(shrink_path -f) %{$purple%}%(!.#.%%) ${PR_RST}'
fi

# right prompt
# prompt when the last command was unsuccessful
PROMPT_STATUS="%F{red}%(?..[%?])%f" # Show exit status of last command in red, if non-zero
RPS1="${PROMPT_STATUS}"

(( $+functions[virtualenv_prompt_info] )) && RPS1+='$(virtualenv_prompt_info)'
RPS1+="%{$gray%}%B[%*]%b%f" # 24hr clock in gray
