#!/usr/bin/env bash
# Distribuicao e checksums portaveis, sem incluir o pacote dentro dele mesmo.
package_release() {
    local source_dir="$1" output_archive="$2"
    local release_dir
    release_dir=$(dirname "$output_archive")
    echo "[7/7] Empacotando versao de distribuicao..."

    # Sistema de arquivos: tar e gzip (Conceito 03)
    local -a artifacts=(docs metrics reports index.html ui)
    [ ! -d "$source_dir/assets" ] || artifacts+=(assets)
    tar -czf "$output_archive" -C "$source_dir" "${artifacts[@]}" || return 1

    # Permissoes simbolicas: chmod (Conceito 04)
    chmod u=rw,go=r "$output_archive"

    (cd "$release_dir" && sha256sum "$(basename "$output_archive")") > "${output_archive}.sha256"
    # MD5 preservado apenas para compatibilidade; SHA-256 e o checksum principal.
    if command -v md5sum &>/dev/null; then
        (cd "$release_dir" && md5sum "$(basename "$output_archive")") > "${output_archive}.md5"
        echo "Release bundle gerado com sucesso: $output_archive"
        echo "Checksum MD5: $(cat "${output_archive}.md5")"
    else
        cksum "$output_archive" > "${output_archive}.cksum"
        echo "Release bundle gerado com sucesso: $output_archive"
        echo "Checksum CKSUM: $(cat "${output_archive}.cksum")"
    fi
}
