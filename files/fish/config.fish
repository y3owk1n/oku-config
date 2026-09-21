# Programs that oku installed come first on PATH.
test -x "$HOME/.local/bin/oku"; and "$HOME/.local/bin/oku" hook fish | source

# Session variables, set once per login tree. A shell inside tmux keeps the
# TERM that tmux gave it, because the guard is exported.
if not set -q __session_vars_set
    set -gx __session_vars_set 1
    set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME $HOME/.config
    set -q XDG_DATA_HOME; or set -gx XDG_DATA_HOME $HOME/.local/share
    set -q XDG_CACHE_HOME; or set -gx XDG_CACHE_HOME $HOME/.cache
    set -q XDG_STATE_HOME; or set -gx XDG_STATE_HOME $HOME/.local/state
    set -gx XDG_BIN_HOME $HOME/.local/bin
    set -gx SHELL $XDG_DATA_HOME/oku/profiles/global/current/bin/fish
    set -gx LANG en_US.UTF-8
    set -gx LC_ALL en_US.UTF-8
    set -gx TERM xterm-256color
    set -gx COLORTERM truecolor
    set -gx TERMINAL ghostty
    set -gx KEYTIMEOUT 1
    set -gx EDITOR nvim
    set -gx VISUAL nvim
    set -gx GIT_EDITOR nvim
    set -gx PAGER less
    set -gx LESS -R
    set -gx CLICOLOR 1
    set -gx SYSTEMD_COLORS true
    set -gx RIPGREP_CONFIG_PATH $XDG_CONFIG_HOME/ripgrep/ripgreprc
end

# fzf. The colours come from conf.d/theme.fish, which oku renders.
# An empty FZF_CTRL_R_COMMAND turns the history widget off, atuin owns ctrl-r.
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --exclude .git'
set -gx FZF_DEFAULT_OPTS "--style full --layout reverse --tmux center $theme_fzf_colors"
set -gx FZF_CTRL_R_COMMAND ''
set -gx FZF_TMUX 1
set -gx FZF_TMUX_OPTS '-p 50%'

# Append so that oku's programs keep precedence over Homebrew ones
if test -x /opt/homebrew/bin/brew
    fish_add_path --append --path /opt/homebrew/bin /opt/homebrew/sbin
end

# functions/__autols_hook.fish has an event hook, so it must be sourced.
# fish does not autoload a function for an event.
source $__fish_config_dir/functions/__autols_hook.fish

__load-em
__autols_hook

status is-interactive; and begin
    alias c clear
    type -q bat; and alias cat bat
    alias gg lazygit

    # eza has no macOS program from upstream yet, see lists/packages-todo.md.
    # Without it ls stays the system one.
    if type -q eza
        alias eza 'eza --icons auto --git'
        alias la 'eza -a'
        alias ll 'eza -l'
        alias lla 'eza -la'
        alias ls eza
        alias lt 'eza --tree'
    end
    alias s 'sesh connect $(sesh list --icons | fzf --ansi)'
    alias tx 'tmux kill-server'
    alias vim nvim
    alias x exit

    set fish_greeting # Disable greeting

    # Disable Fish's native history by using a dummy session
    set -x fish_history ""

    if test -n "$GHOSTTY_RESOURCES_DIR"
        source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
    end

    set -gx MANPATH /opt/homebrew/share/man $MANPATH

    if not contains /opt/homebrew/share/fish/vendor_completions.d $fish_complete_path
        set -gx fish_complete_path $fish_complete_path /opt/homebrew/share/fish/vendor_completions.d
    end

    command -q fzf; and fzf --fish | source
    command -q zoxide; and zoxide init fish | source

    if test "$TERM" != dumb; and command -q starship
        starship init fish | source
        enable_transience
    end

    command -q atuin; and atuin init fish --disable-up-arrow | source
    command -q direnv; and direnv hook fish | source
end
