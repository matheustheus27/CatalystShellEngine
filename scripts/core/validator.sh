#!/usr/bin/env bash
# Auditoria de referencias e ancoras compartilhada pela CLI.
validate_assets_and_links() {
    local doc_file="$1" base_dir="$2" docs_dir="$3"
    echo "[4/7] Auditando links e imagens via grep com metacaracteres..."

    # Testes condicionais com if (Conceito 14)
    if [ ! -f "$doc_file" ]; then
        echo "Documento completo inexistente. Execute o build primeiro." >&2
        return 1
    fi

    # Expressao regular estendida (grep -E) com metacaracteres: ^, !, \[, \], +, (, ) (Conceito 18)
    local link_pattern='!?\[[^]]*\]\(([^)]+)\)'
    local broken_links=0
    local headings
    headings=$(awk '
        /^[ \t]*(```|~~~)/ {code=!code; next}
        !code && /^#{1,3} / {title=$0; sub(/^#+ /,"",title); title=tolower(title); gsub(/[^a-z0-9_-]/,"",title); print title}
    ' "$doc_file")

    # Pipes avancados com while e redirecionamento de entrada < (Conceitos 07 e 08)
    while IFS= read -r match; do
        [ -z "$match" ] && continue
        # Expansao avancada de substituicao de padrao (Conceito 13)
        local raw_url
        raw_url=$(echo "$match" | sed -E 's/^!?\[[^]]*\]\(([^)]+)\)/\1/')

        # Teste com expressao regular Bash =~ (Conceito 14)
        if [[ "$raw_url" == \#* ]]; then
            if ! grep -Fxq -- "${raw_url#\#}" <<< "$headings"; then
                echo "  [FALHA] Ancora inexistente: $raw_url" >&2
                broken_links=$((broken_links + 1))
            fi
        elif [[ ! "$raw_url" =~ ^(https?://|mailto:|data:) ]]; then
            # Remove parametro de ancora se houver (Conceito 13)
            local clean_target="${raw_url%%#*}"
            local target_path="${base_dir}/${clean_target}"
            local target_in_docs="${docs_dir}/${clean_target}"

            if [ -f "$target_path" ] || [ -d "$target_path" ] || [ -f "$target_in_docs" ]; then
                echo "  [OK] Referencia validada: $clean_target"
            else
                echo "  [AVISO] Referencia local pendente: $clean_target"
                broken_links=$((broken_links + 1))
            fi
        fi
    done < <(awk '/^[ \t]*(```|~~~)/ {code=!code; next} !code {gsub(/`[^`]*`/, ""); print}' "$doc_file" | grep -E -o "$link_pattern" || true)

    if [ "$broken_links" -eq 0 ]; then
        echo "Todos os links e referencias locais foram validados com sucesso!"
    else
        echo "Auditoria concluida: $broken_links referencias locais requerem atencao."
        return 1
    fi
}
