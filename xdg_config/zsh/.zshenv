source "$HOME/.cargo/env"

export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_BIN_HOME=$HOME/.local/bin
export XDG_LIB_HOME=$HOME/.local/lib
export XDG_CACHE_HOME=$HOME/.cache
export XDG_STATE_HOME=$HOME/.local/state
export PATH="$XDG_BIN_HOME:$PATH"

export HISTFILE="$XDG_STATE_HOME"/zsh/history
export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd
