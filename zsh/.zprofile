eval "$(/opt/homebrew/bin/brew shellenv)"

export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
