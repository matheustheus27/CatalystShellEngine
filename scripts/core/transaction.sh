#!/usr/bin/env bash
# Cada escritor trabalha em uma copia privada; apenas o commit altera dist/.
sync_output_tree() {
    local source="$1" destination="$2" entry relative target scratch
    mkdir -p "$destination" || return 1
    chmod 755 "$destination" || return 1
    while IFS= read -r -d '' entry; do
        relative="${entry#"$source/"}"
        target="$destination/$relative"
        if [ -d "$entry" ] && [ ! -L "$entry" ]; then
            mkdir -p "$target" || return 1
        elif [ -L "$entry" ] && [ -L "$target" ] && [ "$(readlink "$entry")" = "$(readlink "$target")" ]; then
            continue
        elif [ ! -L "$entry" ] && [ ! -L "$target" ] && [ -f "$target" ] && cmp -s "$entry" "$target"; then
            continue
        else
            scratch=$(mktemp "$(dirname "$target")/.publish.XXXXXXXX") || return 1
            cp -a -- "$entry" "$scratch" || { rm -f "$scratch"; return 1; }
            mv -Tf -- "$scratch" "$target" || { rm -f "$scratch"; return 1; }
        fi
    done < <(find "$source" -mindepth 1 -print0)
    while IFS= read -r -d '' entry; do
        relative="${entry#"$destination/"}"
        if [ ! -e "$source/$relative" ] && [ ! -L "$source/$relative" ]; then
            if [ -d "$entry" ] && [ ! -L "$entry" ]; then rmdir -- "$entry" || return 1
            else rm -f -- "$entry" || return 1; fi
        fi
    done < <(find "$destination" -depth -mindepth 1 -print0)
}

# O chamador deve possuir o lock exclusivo de publicacao.
recover_publication() {
    local published="$1" state="$2"
    if [ -f "$state/in-progress" ]; then
        sync_output_tree "$state/previous" "$published"
        rm -f "$state/in-progress"
        rm -rf -- "$state/previous"
    fi
    if [ ! -e "$published" ] && [ ! -L "$published" ] && [ -d "$state/previous" ]; then
        mv -T "$state/previous" "$published"
    fi
}

cleanup_transaction() {
    local status="$1"
    trap - EXIT
    if [ -f "$STATE_DIR/in-progress" ]; then
        if sync_output_tree "$STATE_DIR/previous" "$PUBLISHED_DIR"; then
            rm -f "$STATE_DIR/in-progress"
            rm -rf -- "$STATE_DIR/previous"
        else
            echo "Recuperacao pendente em $STATE_DIR/previous; nao remova esse diretorio." >&2
        fi
    fi
    if [ "$MOVED_PREVIOUS" = 1 ]; then
        if [ ! -e "$PUBLISHED_DIR" ] && [ ! -L "$PUBLISHED_DIR" ]; then
            mv -T "$STATE_DIR/previous" "$PUBLISHED_DIR" || true
        fi
    fi
    [ -z "$PENDING_LINK" ] || rm -f -- "$PENDING_LINK"
    # Um sinal pode chegar imediatamente apos o rename do link, antes de limpar
    # a variavel. Nunca apague a geracao que ja se tornou a publicacao atual.
    if [ -n "$STAGE_DIR" ] && [ "$(realpath -m "$PUBLISHED_DIR")" != "$STAGE_DIR" ]; then
        rm -rf -- "$STAGE_DIR"
    fi
    exit "$status"
}

begin_transaction() {
    STATE_DIR="$BASE_DIR/.catalyst"
    mkdir -p "$STATE_DIR"
    # Arquivo estavel: nao remover o lock depois do uso (evita locks em inodes distintos).
    exec 9>"$STATE_DIR/build.lock"
    flock -x 9
    exec 8>"$STATE_DIR/publish.lock"
    STAGE_DIR="" PENDING_LINK="" MOVED_PREVIOUS=0
    trap 'cleanup_transaction "$?"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    flock -x 8
    recover_publication "$PUBLISHED_DIR" "$STATE_DIR"
    flock -u 8
    STAGE_DIR=$(mktemp -d "$STATE_DIR/stage.XXXXXXXX")
    if [ "$1" != clean ] && [ -d "$PUBLISHED_DIR" ]; then
        cp -a "$PUBLISHED_DIR/." "$STAGE_DIR/"
    fi
    # Compartilhada com configure_output_paths, definida pelo orquestrador.
    # shellcheck disable=SC2034
    DIST_DIR="$STAGE_DIR"
    configure_output_paths
}

publish_transaction() {
    local mode="${CATALYST_PUBLISH_MODE:-auto}" filesystem previous_target="" generation
    case "$mode" in
        auto)
            filesystem=$(stat -f -c %T "$BASE_DIR")
            case "$filesystem" in
                v9fs|9p|drvfs) mode=directory ;;
                *) mode=symlink ;;
            esac
            ;;
        directory|symlink) ;;
        *) echo 'CATALYST_PUBLISH_MODE deve ser auto, symlink ou directory.' >&2; return 1 ;;
    esac
    flock -x 8
    if [ "$mode" = symlink ]; then
        previous_target=$(realpath -m "$PUBLISHED_DIR")
        generation="$STATE_DIR/generation.${STAGE_DIR##*.}"
        mv -T "$STAGE_DIR" "$generation"
        STAGE_DIR="$generation"
        PENDING_LINK="$STATE_DIR/pending.${generation##*.}"
        ln -s ".catalyst/$(basename "$generation")" "$PENDING_LINK"
        # Migracao unica de dist/ legado: protegida pelo lock de publicacao.
        if [ -d "$PUBLISHED_DIR" ] && [ ! -L "$PUBLISHED_DIR" ]; then
            rm -rf -- "$STATE_DIR/previous"
            mv -T "$PUBLISHED_DIR" "$STATE_DIR/previous"
            MOVED_PREVIOUS=1
        fi
        # rename do link e atomico; leitores veem a geracao anterior ou a nova.
        mv -Tf "$PENDING_LINK" "$PUBLISHED_DIR"
        PENDING_LINK="" STAGE_DIR=""
        for generation in "$STATE_DIR"/generation.*; do
            [ -d "$generation" ] || continue
            if [ "$generation" != "$(realpath "$PUBLISHED_DIR")" ] && [ "$generation" != "$previous_target" ]; then
                rm -rf -- "$generation"
            fi
        done
    else
        # DrvFS nao oferece rename-exchange e seus symlinks nao sao legiveis
        # pelo Windows. Um journal e o flock protegem leitores cooperantes.
        rm -rf -- "$STATE_DIR/previous"
        mkdir -p "$STATE_DIR/previous"
        if [ -d "$PUBLISHED_DIR" ]; then
            cp -a "$PUBLISHED_DIR/." "$STATE_DIR/previous/"
        fi
        touch "$STATE_DIR/in-progress"
        sync_output_tree "$STAGE_DIR" "$PUBLISHED_DIR"
        rm -f "$STATE_DIR/in-progress"
    fi
    MOVED_PREVIOUS=0
    rm -rf -- "$STATE_DIR/previous"
    flock -u 8
    echo "Publicacao concluida: $PUBLISHED_DIR (modo $mode)"
}

run_transaction() (
    local command="$1"
    begin_transaction "$command"
    run_pipeline "$@"
    # validate audita os fontes atuais sem modificar a ultima publicacao.
    if [ "$command" != validate ]; then publish_transaction; fi
)

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    set -eo pipefail
    if [ "${1:-}" = recover ] && [ $# -eq 3 ]; then
        recover_publication "$2" "$3"
    else
        echo 'Uso: transaction.sh recover PUBLICACAO ESTADO' >&2
        exit 1
    fi
fi
