#!/usr/bin/env bash
# GNU AWK indexa os fontes antes de reescrever referencias entre capitulos.
consolidate_documents() {
    local docs_dir="$1" output_file="$2" base_dir="$3" doc relative
    local work="${output_file}.parser.tmp" program="$base_dir/scripts/core/markdown.awk"
    local -a chapters=() markdown=()
    mkdir -p "$work"
    : > "$work/chapters"
    : > "$work/files"
    TOTAL_DOCS=0
    while IFS= read -r -d '' doc; do
        if [ -f "$doc" ]; then
            relative="${doc#"$base_dir/"}"
            if [[ "$relative" == *$'\n'* || "$relative" == *$'\t'* ]]; then
                echo 'Nomes de capitulos nao podem conter tab ou quebra de linha.' >&2
                return 1
            fi
            chapters+=("$doc")
            printf '%s\n' "$relative" >> "$work/chapters"
            TOTAL_DOCS=$((TOTAL_DOCS + 1))
        fi
    done < <(find "$docs_dir" -type f -name '*.md' -print0 | sort -zV)
    if [ "$TOTAL_DOCS" -eq 0 ]; then
        echo "Nenhum capitulo Markdown encontrado em $docs_dir" >&2
        return 1
    fi
    [ $TOTAL_DOCS -gt 0 ] && echo "Total de capitulos detectados: $TOTAL_DOCS"
    markdown=("${chapters[@]}")
    while IFS= read -r -d '' doc; do
        relative="${doc#"$base_dir/"}"
        [[ "$relative" != *$'\n'* && "$relative" != *$'\t'* ]] || continue
        printf '%s\n' "$relative" >> "$work/files"
        if [[ "$doc" == *.md && "$doc" != "$docs_dir/"* ]]; then markdown+=("$doc"); fi
    done < <(find "$base_dir" -mindepth 1         \( -name '.*' -o -name node_modules -o -path "$base_dir/dist" \) -prune -o -type f -print0)
    local headings_file links_file
    headings_file="$(dirname "$output_file")/headings.tsv"
    links_file="$(dirname "$output_file")/links.tsv"
    : > "$headings_file"
    : > "$links_file"
    gawk -v mode=index -v root="$base_dir" -v chapter_list="$work/chapters"         -v file_list="$work/files" -f "$program" "${markdown[@]}" > "$work/index"
    gawk -v mode=rewrite -v root="$base_dir" -v chapter_list="$work/chapters"         -v file_list="$work/files" -v index_file="$work/index" -v headings_file="$headings_file"         -v chapters_file="$(dirname "$output_file")/chapters.json" -v links="$links_file" -f "$program" "${chapters[@]}" > "$work/document"
    sanitize_markdown "$work/document" "$output_file"
    rm -rf -- "$work"
    echo "Documento consolidado: $output_file"
}

generate_toc() {
    local doc_file="$1" toc_file="$2" metadata json_file
    metadata="$(dirname "$doc_file")/headings.tsv"
    json_file="$(dirname "$doc_file")/headings.json"
    printf '<!-- Sumario gerado pelo indice GNU AWK -->\n## Sumário da Documentação\n\n' > "$toc_file"
    gawk -v json="$json_file" -f "${BASH_SOURCE[0]%/*}/toc.awk" "$metadata" >> "$toc_file"
}
