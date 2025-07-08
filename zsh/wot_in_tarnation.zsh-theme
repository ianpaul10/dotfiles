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
RPS1="${PROMPT_STATUS}%{$gray%}%B[%*]%b%f" # [error_code][24hr clock in gray]


# source: https://gitlab.freedesktop.org/Per_Bothner/specifications/blob/master/proposals/semantic-prompts.md
# credit: https://wezterm.org/config/lua/keyassignment/ScrollToPrompt.html?h=scroll
# wraps prompt, input, output with proper OSC chars to allow jumping to previous prompts
# probably not a theme but have it here for now
_prompt_executing=""
function __prompt_precmd() {
    local ret="$?"
    if test "$_prompt_executing" != "0"
    then
      _PROMPT_SAVE_PS1="$PS1"
      _PROMPT_SAVE_PS2="$PS2"
      PS1=$'%{\e]133;P;k=i\a%}'$PS1$'%{\e]133;B\a\e]122;> \a%}'
      PS2=$'%{\e]133;P;k=s\a%}'$PS2$'%{\e]133;B\a%}'
    fi
    if test "$_prompt_executing" != ""
    then
       printf "\033]133;D;%s;aid=%s\007" "$ret" "$$"
    fi
    printf "\033]133;A;cl=m;aid=%s\007" "$$"
    _prompt_executing=0
}
function __prompt_preexec() {
    PS1="$_PROMPT_SAVE_PS1"
    PS2="$_PROMPT_SAVE_PS2"
    printf "\033]133;C;\007"
    _prompt_executing=1
}
preexec_functions+=(__prompt_preexec)
precmd_functions+=(__prompt_precmd)
