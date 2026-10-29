#!/usr/bin/env bash
# As referencias sao resolvidas pelo mesmo indice usado no sumario e no HTML.
validate_assets_and_links() {
    local doc_file="$1" base_dir="$2" docs_dir="$3" manifest kind file line target destination resolved
    manifest="$(dirname "$doc_file")/links.tsv"
    [ -d "$docs_dir" ] && [ -f "$manifest" ] || { echo 'Indice de links ausente.' >&2; return 1; }
    if grep -E '^ERROR[[:space:]]' "$manifest" >&2; then return 1; fi
    while IFS=$'\t' read -r kind file line target destination; do
        [ "$kind" = ASSET ] || continue
        resolved=$(realpath -e "$base_dir/$target") || return 1
        if [[ "$resolved" != "$base_dir/"* ]] || [ ! -f "$resolved" ]; then
            echo "Ativo fora do projeto: $file:$line: $target" >&2
            return 1
        fi
    done < "$manifest"
    echo 'Links, referencias, fragmentos e caminhos locais validados.'
}
