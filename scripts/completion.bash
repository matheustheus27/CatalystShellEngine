#!/usr/bin/env bash
# ==============================================================================
# Catalyst Shell Engine - Bash Completion Script
# Para ativar: source scripts/completion.bash
# ==============================================================================

_catalyst_completions() {
    local cur prev commands
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    commands="all build validate toc sanitize stats pack serve clean report test watch help"

    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
        return 0
    fi

    if [ "$prev" = "serve" ]; then
        COMPREPLY=( $(compgen -W "--stop stop --port -p 8000 8080" -- "$cur") )
        return 0
    fi
}

complete -F _catalyst_completions catalyst.sh ./catalyst.sh
