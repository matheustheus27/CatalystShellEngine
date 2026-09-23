#!/usr/bin/env bash
# ==============================================================================
# Catalyst Shell Engine - Validator (Grep com Metacaracteres)
# ==============================================================================
set -e

# Valida referencias a imagens e links usando grep com metacaracteres (Conceito 18)
validate_assets_and_links() {
    local doc_file="$1"
    local base_dir="$2"
    local errors=0

    echo "Auditando referencias no arquivo: $(basename "$doc_file")..."

    # Expressao regular estendida (grep -E) com metacaracteres: ^, !, \[, \], +, (, )
    local img_pattern='!\[[^]]*\]\(([^)]+)\)'
    local found_images
    found_images=$(grep -E -o "$img_pattern" "$doc_file" 2>/dev/null || true)

    if [ -n "$found_images" ]; then
        while IFS= read -r match; do
            local path
            path=$(echo "$match" | sed -E 's/!\[[^]]*\]\(([^)]+)\)/\1/')
            
            # Se for link local (nao inicia com http)
            if [[ ! "$path" =~ ^https?:// ]]; then
                local clean_path="${path%%#*}"
                local full_target="${base_dir}/${clean_path}"
                if [ ! -f "$full_target" ]; then
                    echo "  [FALHA] Imagem referenciada nao encontrada: $clean_path" >&2
                    errors=$((errors + 1))
                else
                    echo "  [OK] Imagem validada: $clean_path"
                fi
            fi
        done <<< "$found_images"
    fi

    return "$errors"
}
