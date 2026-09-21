function __autols_hook --description="Auto ls" --on-variable="PWD"
    if not set -q __autols_initialized
        set -g __autols_initialized 1
        return
    end

    if test "$PWD" != "$__autols_last"
        echo
        ls
        set -g __autols_last $PWD
    end
end
