#!/usr/bin/env bash
# Consolidacao e sumario: uma unica implementacao usada pela CLI.
consolidate_documents() {
    local docs_dir="$1" output_file="$2"
    echo "[2/7] Consolidando capitulos de documentacao..."

    local temp_concat
    temp_concat=$(mktemp "${output_file}.concat.XXXXXXXX")
    TOTAL_DOCS=0
    : > "$temp_concat"

    # Comandos de repeticao: for (Conceito 17)
    # Pipes e ordenacao: sort (Conceito 02 e 08)
    while IFS= read -r -d '' doc; do
        # Teste condicional com test/if: arquivos (Conceito 14)
        if [ -f "$doc" ]; then
            local filename
            filename="$(basename "$doc")"

            # Expansao aritmetica: $(( ... )) (Conceito 09)
            TOTAL_DOCS=$((TOTAL_DOCS + 1))

            {
                printf '\n<!-- Capitulo: %s -->\n\n' "$filename"
                cat "$doc"
                echo ""
            } >> "$temp_concat"
        fi
    done < <(find "$docs_dir" -maxdepth 1 -type f -name '*.md' -print0 | sort -zV)

    if [ "$TOTAL_DOCS" -eq 0 ]; then
        echo "Nenhum capitulo Markdown encontrado em $docs_dir" >&2
        return 1
    fi

    # Outras formas de desvio: && (Conceito 16)
    [ $TOTAL_DOCS -gt 0 ] && echo "Total de capitulos detectados: $TOTAL_DOCS"

    sanitize_markdown "$temp_concat" "$output_file"

    rm -f "$temp_concat"
    echo "Documento unificado gerado em: $OUTPUT_DOC"
}

generate_toc() {
    local doc_file="$1" toc_file="$2"
    echo "[3/7] Gerando Sumario (TOC) hierarquico com AWK..."

    printf '<!-- Sumario Hierarquico Gerado Automaticamente -->\n## 📑 Sumário da Documentação\n\n' > "$toc_file"

    # Programa em AWK (Conceito 20):
    awk '
    BEGIN {
        h1 = 0; h2 = 0; h3 = 0; in_code = 0;
    }
    /^[ \t]*(```|~~~)/ {
        in_code = !in_code;
        next;
    }
    in_code {
        next;
    }
    /^# [^#]/ {
        h1++; h2 = 0; h3 = 0;
        title = substr($0, 3);
        anchor = tolower(title);
        gsub(/[^a-z0-9_-]/, "", anchor);
        printf("%d. [%s](#%s)\n", h1, title, anchor);
    }
    /^## [^#]/ {
        h2++; h3 = 0;
        title = substr($0, 4);
        anchor = tolower(title);
        gsub(/[^a-z0-9_-]/, "", anchor);
        printf("   %d.%d. [%s](#%s)\n", h1, h2, title, anchor);
    }
    /^### [^#]/ {
        h3++;
        title = substr($0, 5);
        anchor = tolower(title);
        gsub(/[^a-z0-9_-]/, "", anchor);
        sub_h2 = (h2 == 0) ? 1 : h2;
        printf("      %d.%d.%d. [%s](#%s)\n", h1, sub_h2, h3, title, anchor);
    }
    ' "$doc_file" >> "$toc_file"

    echo "Sumario gerado com sucesso em: $toc_file"
}
