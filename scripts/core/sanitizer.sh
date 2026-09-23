#!/usr/bin/env bash
# ==============================================================================
# Catalyst Shell Engine - Markdown Sanitizer (Uso intensivo de sed)
# ==============================================================================
set -e

sanitize_markdown() {
    local input_file="$1"
    local output_file="$2"

    if [ ! -f "$input_file" ]; then
        echo "Arquivo fonte nao encontrado: $input_file" >&2
        return 1
    fi

    # Programa em sed (Conceito 19):
    # 1. Remove espacos e tabs em branco no final de linhas: s/[ \t]+$//
    # 2. Padroniza cabecalhos garantindo espaco unico apos hashtags: s/^(#+)[ \t]*/\1 /
    sed -E \
        -e 's/[ \t]+$//' \
        -e 's/^(#+)[ \t]+/\1 /' \
        "$input_file" > "$output_file"
}
