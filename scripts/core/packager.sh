#!/usr/bin/env bash
# Distribuicao e checksums portaveis, sem incluir o pacote dentro dele mesmo.
package_release() (
    set -eo pipefail
    local source_dir="$1" output_archive="$2"
    local release_dir work artifact epoch="${SOURCE_DATE_EPOCH:-0}" temporary
    release_dir=$(dirname "$output_archive")
    echo "[7/7] Empacotando versao de distribuicao..."

    # Sistema de arquivos: tar e gzip (Conceito 03)
    local -a artifacts=(docs metrics reports index.html ui)
    [ ! -d "$source_dir/assets" ] || artifacts+=(assets)
    work=$(mktemp -d "$release_dir/.package.XXXXXXXX")
    temporary=$(mktemp "$release_dir/.archive.XXXXXXXX")
    trap 'rm -rf -- "$work"; rm -f -- "$temporary"' EXIT
    for artifact in "${artifacts[@]}"; do
        cp -a --no-preserve=links -- "$source_dir/$artifact" "$work/"
    done
    find "$work" -type d -exec chmod 755 {} +
    find "$work" -type f -exec chmod 644 {} +
    # GNU tar + gzip -n: ordem, data, identidade e cabecalho independem do host.
    LC_ALL=C env -u TAR_OPTIONS tar --sort=name --format=gnu --mtime="@$epoch" \
        --owner=0 --group=0 --numeric-owner -cf - -C "$work" "${artifacts[@]}" | env -u GZIP gzip -n -9 > "$temporary"
    mv -Tf "$temporary" "$output_archive"

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
)
