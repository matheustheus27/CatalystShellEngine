#!/usr/bin/env bash
# Normalizacao Markdown compartilhada pelo parser e pela CLI.
sanitize_markdown() {
    local input_file="$1" output_file="$2"
    # Programa em sed: Higienizacao e padronizacao de cabecalhos e ancoras internas (Conceito 19)
    sed -E \
        -e 's/[ \t]+$//' \
        -e 's/^(#+)[ \t]+/\1 /' \
        -e 's/\(00-cover\.md\)/(#catalystshellengine)/g' \
        -e 's/\(01-overview\.md\)/(#01visogeralemotivao)/g' \
        -e 's/\(02-architecture\.md\)/(#02arquiteturaeengenhariadepipeline)/g' \
        -e 's/\(03-concepts\.md\)/(#03conformidadecomoenunciado20conceitos)/g' \
        -e 's/\(04-usage-guide\.md\)/(#04manualoperacionaldacli)/g' \
        -e 's/\(05-benchmarks\.md\)/(#05anlisecomparativaebenchmarks)/g' \
        -e 's/\(06-conclusion\.md\)/(#06conclusoeresultados)/g' \
        -e 's/\(CEFET_REPORT\.md\)/(#03conformidadecomoenunciado20conceitos)/g' \
        -e 's/\(catalyst\.sh\)/(#04manualoperacionaldacli)/g' \
        "$input_file" > "$output_file"

}
