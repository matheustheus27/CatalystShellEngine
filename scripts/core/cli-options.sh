#!/usr/bin/env bash
# Opcoes comuns independentes das opcoes de cada subcomando.
parse_cli() {
    COMMAND=""
    CLI_ARGS=()
    local docs="$BASE_DIR/docs" output="$BASE_DIR/dist" selected=0 value
    while [ $# -gt 0 ]; do
        case "$1" in
            --docs|--output)
                if [ $# -lt 2 ] || [[ -z "$2" || "$2" == --* ]]; then
                    echo "Informe um caminho apos $1." >&2; return 1
                fi
                value="$2"
                if [ "$1" = --docs ]; then docs="$value"; else output="$value"; fi
                selected=1; shift 2; continue
                ;;
            --docs=*) docs="${1#*=}"; selected=1 ;;
            --output=*) output="${1#*=}"; selected=1 ;;
            --help|-h) COMMAND=help ;;
            *)
                if [ -z "$COMMAND" ]; then COMMAND="$1"; else CLI_ARGS+=("$1"); fi
                ;;
        esac
        shift
    done
    COMMAND="${COMMAND:-help}"
    case "$COMMAND" in
        help) return 0 ;;
        test|demo|completion)
            [ "$selected" = 0 ] || { echo "$COMMAND nao aceita --docs ou --output." >&2; return 1; }
            return 0 ;;
    esac
    configure_project_paths "$docs" "$output"
}

configure_project_paths() {
    local docs="$1" output="$2" parent component resolved
    for component in "$docs" "$output"; do
        if [[ -z "$component" || "$component" == *$'\n'* || "$component" == *$'\r'* || "$component" == *$'\t'* ]]; then
            echo 'Caminho vazio ou com caracteres de controle.' >&2; return 1
        fi
    done
    DOCS_DIR=$(realpath -m -- "$docs")
    SOURCE_ROOT=$(dirname "$DOCS_DIR")
    [ "$SOURCE_ROOT" != / ] || { echo 'Selecione uma pasta de capitulos dentro de um projeto.' >&2; return 1; }
    output=$(realpath -ms -- "$output")
    parent=$(realpath -m -- "$(dirname "$output")")
    PUBLISHED_DIR=$(realpath -ms -- "$parent/$(basename "$output")")
    case "$COMMAND" in
        build|all|validate|toc|sanitize|stats|watch)
            [ -d "$DOCS_DIR" ] || { echo "Pasta de capitulos inexistente: $DOCS_DIR" >&2; return 1; } ;;
    esac
    # Nunca substituir fontes, a raiz do projeto ou diretorios do motor.
    if [[ "$PUBLISHED_DIR" = / || "$SOURCE_ROOT/" == "$PUBLISHED_DIR/"* ||
          "$BASE_DIR/" == "$PUBLISHED_DIR/"* || "$PUBLISHED_DIR/" == "$DOCS_DIR/"* ||
          "$PUBLISHED_DIR" == */.catalyst || "$PUBLISHED_DIR" == */.catalyst/* ||
          "$PUBLISHED_DIR" == */.catalyst-* || "$PUBLISHED_DIR" == */.catalyst-*/* ]]; then
        echo 'A saida nao pode conter os fontes nem ocupar pastas de controle.' >&2; return 1
    fi
    for component in scripts templates vendor images .git .agents .codex node_modules; do
        if [[ "$PUBLISHED_DIR/" == "$BASE_DIR/$component/"* ]]; then
            echo "Saida protegida: $PUBLISHED_DIR" >&2; return 1
        fi
    done
    STATE_DIR=$(publication_state "$PUBLISHED_DIR")
    if [ -L "$PUBLISHED_DIR" ]; then
        resolved=$(realpath -m "$PUBLISHED_DIR")
        [[ "$resolved" == "$STATE_DIR"/generation.* ]] || {
            echo 'Link de saida nao pertence a esta publicacao.' >&2; return 1;
        }
    elif [ -e "$PUBLISHED_DIR" ] && [ ! -d "$PUBLISHED_DIR" ]; then
        echo 'A saida precisa ser um diretorio.' >&2; return 1
    fi
    resolved=$(realpath -m "$PUBLISHED_DIR")
    if [[ "$SOURCE_ROOT/" == "$resolved/"* || "$DOCS_DIR/" == "$resolved/"* ]]; then
        echo 'As fontes nao podem estar dentro da publicacao selecionada.' >&2; return 1
    fi
    if [ -d "$PUBLISHED_DIR" ] && [ "$PUBLISHED_DIR" != "$BASE_DIR/dist" ] &&
       [ -n "$(find "$PUBLISHED_DIR" -mindepth 1 -maxdepth 1 -print -quit)" ] &&
       ! grep -qxF 'Catalyst Shell Engine output v1' "$PUBLISHED_DIR/.catalyst-output" 2>/dev/null; then
        echo 'A saida existente nao foi gerada pelo Catalyst; escolha uma pasta vazia.' >&2; return 1
    fi
    # Uma saida nao pode ser aninhada dentro de outra publicacao gerenciada.
    component="$parent"
    while [ "$component" != / ]; do
        if [ -f "$component/.catalyst-output" ]; then
            echo 'A saida nao pode ficar dentro de outra publicacao.' >&2; return 1
        fi
        component=$(dirname "$component")
    done
    AUDIT_FILE="${PUBLISHED_DIR}.validation.md"
    if [ -e "$AUDIT_FILE" ] && ! head -n 1 "$AUDIT_FILE" | grep -qxF '# Relatório de Validação - Catalyst Shell Engine'; then
        echo "Arquivo de auditoria existente nao pertence ao Catalyst: $AUDIT_FILE" >&2; return 1
    fi
    # Caminho consumido pelo orquestrador e pela transacao.
    # shellcheck disable=SC2034
    DIST_DIR="$PUBLISHED_DIR"
    configure_output_paths
}
