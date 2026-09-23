#!/usr/bin/env bash
# ==============================================================================
# Catalyst Shell Engine - Packager & Release Bundler
# ==============================================================================
set -e

package_release() {
    local source_dir="$1"
    local output_archive="$2"
    local release_dir
    release_dir="$(dirname "$output_archive")"

    mkdir -p "$release_dir"

    # Define permissoes em representacao octal (Conceito 04)
    chmod 755 "$release_dir"

    echo "Compactando pacote de distribuicao..."
    # Uso de tar e gzip (Conceito 03) com redirecionamento de erro (Conceito 07)
    tar -czf "$output_archive" -C "$source_dir" . 2> /dev/null

    # Permissao simbolica no pacote gerado (Conceito 04)
    chmod u=rw,go=r "$output_archive"

    # Calculo de integridade com md5sum ou cksum (Conceito 03)
    if command -v md5sum &>/dev/null; then
        md5sum "$output_archive" > "${output_archive}.md5"
        echo "Checksum MD5 gerado: $(cat "${output_archive}.md5")"
    else
        cksum "$output_archive" > "${output_archive}.cksum"
        echo "Checksum CKSUM gerado: $(cat "${output_archive}.cksum")"
    fi
}
