#!/usr/bin/env bash
# ==============================================================================
# Catalyst Shell Engine - Shell Autocompletion Script
#
# Para ativar no Bash / Git Bash:
#   source scripts/completion.bash
#
# Para ativar permanentemente no Bash:
#   echo "source $(pwd)/scripts/completion.bash" >> ~/.bashrc
#
# Para ativar no Zsh:
#   autoload -U +X bashcompinit && bashcompinit && source scripts/completion.bash
# ==============================================================================

_catalyst_reply() {
    local reply
    COMPREPLY=()
    while IFS= read -r reply; do COMPREPLY+=("$reply"); done < <(compgen "$@")
}

_catalyst_completions() {
    local cur="${2:-}"
    local prev="${3:-}"
    local cword="${COMP_CWORD:-1}"

    # Fallback para arrays COMP_WORDS se parametros posicionais nao foram fornecidos
    if [ -z "$cur" ] && [ -n "${COMP_WORDS:-}" ]; then
        cur="${COMP_WORDS[COMP_CWORD]:-}"
    fi
    if [ -z "$prev" ] && [ -n "${COMP_WORDS:-}" ] && [ "$cword" -gt 0 ]; then
        prev="${COMP_WORDS[COMP_CWORD-1]:-}"
    fi

    local commands="all build validate toc sanitize stats pack serve clean report test watch demo completion help"

    # Encontra o indice onde catalyst(.sh) foi chamado
    local script_idx=-1
    if [ -n "${COMP_WORDS:-}" ]; then
        for ((i=0; i<cword; i++)); do
            if [[ "${COMP_WORDS[i]}" =~ catalyst(\.sh)?$ ]]; then
                script_idx=$i
                break
            fi
        done
    fi

    # Se a chamada foi via 'bash' ou 'sh' e catalyst ainda nao foi especificado
    if [ "$script_idx" -eq -1 ]; then
        if [[ "${COMP_WORDS[0]}" =~ (bash|sh)$ ]]; then
            _catalyst_reply -f -- "$cur"
            return 0
        fi
        # Se for chamada direta catalyst.sh
        if [ "$cword" -le 1 ]; then
            _catalyst_reply -W "$commands" -- "$cur"
            return 0
        fi
    fi

    local target_idx=$((script_idx + 1))

    # 1. Primeiro argumento apos catalyst.sh: lista todos os subcomandos disponiveis
    if [ "$cword" -eq "$target_idx" ]; then
        _catalyst_reply -W "$commands" -- "$cur"
        return 0
    fi

    # 2. Parametros contextuais de cada subcomando
    case "$prev" in
        --docs|--output)
            _catalyst_reply -d -- "$cur"
            return 0
            ;;
        completion)
            _catalyst_reply -W "install uninstall source help" -- "$cur"
            return 0
            ;;
        serve)
            _catalyst_reply -W "--stop stop --restart restart --backend --concurrent --port -p --docs --output 8000 8080 3000" -- "$cur"
            return 0
            ;;
        --backend)
            _catalyst_reply -W "bash threaded" -- "$cur"
            return 0
            ;;
        --port|-p)
            _catalyst_reply -W "8000 8080 3000 5000" -- "$cur"
            return 0
            ;;
    esac
    if [[ "$cur" == -* ]]; then
        _catalyst_reply -W "--docs --output --help" -- "$cur"
    fi
}

# Suporte ao Zsh via modulo de compatibilidade bashcompinit
if [ -n "${ZSH_VERSION:-}" ]; then
    autoload -U +X bashcompinit 2>/dev/null && bashcompinit 2>/dev/null
fi

# Registra completion para todas as formas usuais de chamada
complete -F _catalyst_completions -o default -o bashdefault ./catalyst.sh 2>/dev/null || complete -F _catalyst_completions ./catalyst.sh
complete -F _catalyst_completions -o default -o bashdefault catalyst.sh 2>/dev/null || complete -F _catalyst_completions catalyst.sh
complete -F _catalyst_completions -o default -o bashdefault catalyst 2>/dev/null || complete -F _catalyst_completions catalyst
complete -F _catalyst_completions -o default -o bashdefault bash 2>/dev/null || complete -F _catalyst_completions bash
