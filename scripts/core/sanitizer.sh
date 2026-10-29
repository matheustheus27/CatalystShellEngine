#!/usr/bin/env bash
# Normaliza CRLF sem alterar indentacao, cercas ou hard breaks do Markdown.
sanitize_markdown() {
    local input_file="$1" output_file="$2"
    sed -e 's/\r$//' "$input_file" > "$output_file"
}
