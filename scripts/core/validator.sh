#!/usr/bin/env bash
# As referencias sao resolvidas pelo mesmo indice usado no sumario e no HTML.
write_validation_report() {
    local manifest="$1" output="$2" temporary
    mkdir -p "$(dirname "$output")"
    temporary=$(mktemp "${output}.tmp.XXXXXXXX")
    if gawk -f "$SCRIPTS_DIR/core/validation-report.awk" "$manifest" > "$temporary"; then
        mv -Tf "$temporary" "$output"
    else
        rm -f "$temporary"; return 1
    fi
    echo "Auditoria Markdown: $output"
}

validate_assets_and_links() {
    local doc_file="$1" base_dir="$2" docs_dir="$3" manifest kind file line target _destination resolved checked
    manifest="$(dirname "$doc_file")/links.tsv"
    if [ ! -d "$docs_dir" ] || [ ! -f "$manifest" ]; then
        echo 'Indice de links ausente.' >&2; return 1
    fi
    checked=$(mktemp "${manifest}.checked.XXXXXXXX")
    while IFS=$'\t' read -r kind file line target _destination; do
        if [ "$kind" = ASSET ]; then
            resolved=$(realpath -e "$base_dir/$target" 2>/dev/null) || resolved=""
            if [[ "$resolved" != "$base_dir/"* ]] || [ ! -f "$resolved" ]; then
                kind=ERROR; _destination='Ativo inexistente ou fora do projeto (caminho canonico)'
            fi
        fi
        printf '%s\t%s\t%s\t%s\t%s\n' "$kind" "$file" "$line" "$target" "$_destination" >> "$checked"
    done < "$manifest"
    mv -Tf "$checked" "$manifest"
    write_validation_report "$manifest" "$AUDIT_FILE"
    # O trap da transacao consulta este indicador.
    # shellcheck disable=SC2034
    VALIDATION_PENDING=0
    if grep -E '^ERROR[[:space:]]' "$manifest" >&2; then return 1; fi
    mkdir -p "$REPORTS_OUT_DIR"
    cp "$AUDIT_FILE" "$REPORTS_OUT_DIR/validation.md"
    echo 'Links, referencias, fragmentos e caminhos locais validados.'
}
