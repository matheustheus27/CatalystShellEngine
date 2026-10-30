#!/usr/bin/env bash
# SOURCE_DATE_EPOCH fixa datas dos artefatos, sem alterar o relogio do sistema.
validate_source_date_epoch() {
    if [ "${SOURCE_DATE_EPOCH+x}" ]; then
        if [[ ! "$SOURCE_DATE_EPOCH" =~ ^[0-9]{1,12}$ ]] || ((10#$SOURCE_DATE_EPOCH > 253402300799)); then
            echo 'SOURCE_DATE_EPOCH deve ser um inteiro Unix entre 0 e 253402300799.' >&2
            return 1
        fi
        export SOURCE_DATE_EPOCH="$((10#$SOURCE_DATE_EPOCH))"
    fi
}

artifact_date() {
    if [ "${SOURCE_DATE_EPOCH+x}" ]; then
        LC_ALL=C date -u -d "@$SOURCE_DATE_EPOCH" "$@"
    else
        date "$@"
    fi
}
