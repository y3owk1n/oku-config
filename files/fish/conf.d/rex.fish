# A command of 10s or more reports done or failed to Rex as it ends, with
# OSC 7501. Rex marks the tab when I am not looking at it, and sends a
# macOS notification while it is in the background, as tmux's
# pane-command-finished hook does. A command stopped with ctrl+c reports
# nothing.
set -q REX_BLOCK; or return

function __rex_command_status --on-event fish_postexec
    set -l code $status
    test $CMD_DURATION -ge 10000; or return
    test $code -eq 130; and return

    set -l state done
    set -l word done
    if test $code -ne 0
        set state error
        set word "failed ($code)"
    end
    set -l cmd (string replace -ra '[[:cntrl:]]+' ' ' -- "$argv[1]" | string shorten -m 80)
    set -l msg (printf '%s after %ss: %s' $word (math -s0 $CMD_DURATION / 1000) $cmd | base64 | string join '')
    printf '\e]7501;state=%s:app=fish:msg=%s\e\\' $state $msg
end
