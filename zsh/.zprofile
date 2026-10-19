eval "$(/opt/homebrew/bin/brew shellenv)"

export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

export LOCAL_SCRIPTS_DIR="$HOME/code/dotfiles/scripts"
export PATH="$LOCAL_SCRIPTS_DIR:$PATH"

# Added by tec agent
[[ ! -o interactive ]] && [[ -d /Users/ip_shopify/.local/state/tec/toolchain/base_profile/bin ]] && export PATH="/Users/ip_shopify/.local/state/tec/toolchain/base_profile/bin:$PATH"
