#!/usr/bin/env bash
# Configuracao opcional do perfil do usuario.
manage_completion() {
    local action="${2:-install}" completion_file="$SCRIPTS_DIR/completion.bash" rc_file
    if [ "$action" != source ] && [ "$action" != --source ]; then show_banner; fi
    [ -f "$completion_file" ] || { echo 'Script de completion ausente.' >&2; return 1; }
    if [ -n "${ZSH_VERSION:-}" ] || [[ "${SHELL:-}" =~ zsh$ ]]; then
        rc_file="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        rc_file="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        rc_file="$HOME/.bash_profile"
    else
        rc_file="$HOME/.bashrc"
    fi
    case "$action" in
        source|--source) cat "$completion_file" ;;
        uninstall|--uninstall|-u)
            if [ -f "$rc_file" ]; then
                sed -i '/# Catalyst Shell Engine Autocompletion/,+1d' "$rc_file"
            fi
            echo "Autocompletar removido de $rc_file."
            ;;
        help|--help|-h) echo 'Uso: catalyst.sh completion [install|uninstall|source]' ;;
        install|--install|-i)
            touch "$rc_file"
            if ! grep -Fq 'Catalyst Shell Engine Autocompletion' "$rc_file"; then
                printf '\n# Catalyst Shell Engine Autocompletion\n[ -f %q ] && source %q\n' "$completion_file" "$completion_file" >> "$rc_file"
            fi
            printf 'Autocompletar instalado. Execute: source %q\n' "$completion_file"
            ;;
        *) echo "Acao desconhecida: $action" >&2; return 1 ;;
    esac
}
