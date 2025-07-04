# inspired by af-magic
# also help from https://aamnah.com/notes/sysadmin/zsh-custom-theme-ultimate-guide/

# use extended color palette if available (https://www.ditig.com/256-colors-cheat-sheet)
if [[ $terminfo[colors] -ge 256 ]]; then
    turquoise="%F{81}"
    orange="%F{214}"
    violet="%F{135}"
    gray="%F{241}"
    blue="%F{032}"
    red="%F{red}"
    fuchsia="%F{213}"
else
    turquoise="%F{cyan}"
    orange="%F{yellow}"
    violet="%F{magenta}"
    gray="%F{white}"
    blue="%F{blue}"
    red="%F{red}"
    fuchsia="%F{magenta}"
fi

PR_RST="%f"

# git settings
ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY="%{$violet%}*${PR_RST}"
ZSH_THEME_GIT_PROMPT_SUFFIX="${PR_RST}"

# virtualenv settings
ZSH_THEME_VIRTUALENV_PREFIX=" $FG[075]["
ZSH_THEME_VIRTUALENV_SUFFIX="]%{$reset_color%}"

# primary prompt
# NOTE: if things get slow, swap $(shrink_path -f) with %~ or %c
PS1='%{$blue%}$(shrink_path -f) %{$turquoise%}$(git_prompt_info) %{$orange%}%(!.#.λ) ${PR_RST}'

# primary prompt when no git repo
if [ -z "$(git_current_branch)" ]; then 
PS1='%{$blue%}$(shrink_path -f) %{$orange%}%(!.#.λ) ${PR_RST}'
fi

# right prompt
# prompt when the last command was unsuccessful
PROMPT_STATUS="%F{red}%(?..[%?])%f" # Show exit status of last command in red, if non-zero
RPS1="${PROMPT_STATUS}"

(( $+functions[virtualenv_prompt_info] )) && RPS1+='$(virtualenv_prompt_info)'
RPS1+="%{$gray%}%B[%*]%b%f" # 24hr clock in gray
