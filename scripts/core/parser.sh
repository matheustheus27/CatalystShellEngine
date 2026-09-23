#!/usr/bin/env bash
# ==============================================================================
# Catalyst Shell Engine - Document Parser & TOC Generator
# ==============================================================================
set -e

# Gera Sumario (Table of Contents) hierarquico utilizando AWK (Conceito 20)
generate_toc() {
    local doc_file="$1"
    local toc_file="$2"

    echo "<!-- Table of Contents gerado automaticamente pelo Catalyst Shell Engine -->" > "$toc_file"
    echo "## 📑 Sumário Geral" >> "$toc_file"
    echo "" >> "$toc_file"

    # Programa em AWK (Conceito 20):
    # Varre cabecalhos Markdown (#, ##, ###), numera secoes e gera links ancorados
    awk '
    BEGIN {
        sec1 = 0; sec2 = 0; sec3 = 0; in_code = 0;
    }
    /^```/ {
        in_code = !in_code;
        next;
    }
    in_code {
        next;
    }
    /^# [^#]/ {
        sec1++; sec2 = 0; sec3 = 0;
        title = substr($0, 3);
        anchor = tolower(title);
        gsub(/[^a-z0-9_-]/, "", anchor);
        printf("%d. [%s](#%s)\n", sec1, title, anchor);
    }
    /^## [^#]/ {
        sec2++; sec3 = 0;
        title = substr($0, 4);
        anchor = tolower(title);
        gsub(/[^a-z0-9_-]/, "", anchor);
        printf("   %d.%d. [%s](#%s)\n", sec1, sec2, title, anchor);
    }
    /^### [^#]/ {
        sec3++;
        title = substr($0, 5);
        anchor = tolower(title);
        gsub(/[^a-z0-9_-]/, "", anchor);
        printf("      %d.%d.%d. [%s](#%s)\n", sec1, sec2, sec3, title, anchor);
    }
    ' "$doc_file" >> "$toc_file"
}

# Consolida documentos ordenados (Conceito 02: cat, sort, wc)
consolidate_documents() {
    local docs_dir="$1"
    local output_file="$2"
    local temp_file="${output_file}.tmp"

    > "$temp_file"

    # Ordena capitulos por nome e concatena usando cat e sort (Conceito 02)
    for doc in $(ls "$docs_dir"/*.md 2>/dev/null | sort -V); do
        echo -e "\n<!-- Inicio: $(basename "$doc") -->\n" >> "$temp_file"
        cat "$doc" >> "$temp_file"
        echo -e "\n" >> "$temp_file"
    done

    mv "$temp_file" "$output_file"
}
