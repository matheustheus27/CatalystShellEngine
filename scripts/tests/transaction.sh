#!/usr/bin/env bash
set -eo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURE=$(mktemp -d /tmp/catalyst-transactions.XXXXXXXX)
cleanup() {
    bash "$FIXTURE/catalyst.sh" serve --stop >/dev/null 2>&1 || true
    rm -rf -- "$FIXTURE"
}
trap cleanup EXIT
cp "$ROOT/catalyst.sh" "$FIXTURE/"
cp -R "$ROOT/scripts" "$ROOT/templates" "$ROOT/images" "$FIXTURE/"
mkdir "$FIXTURE/docs" "$FIXTURE/wrappers"
cli() { bash "$FIXTURE/catalyst.sh" "$@"; }
snapshot() { (cd "$FIXTURE/dist" && find . -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum); }
reject() { if "$@" >/dev/null 2>&1; then echo "Falha esperada: $*" >&2; exit 1; fi; }
assert_no_staging() { test -z "$(find "$FIXTURE/.catalyst" -maxdepth 1 -name 'stage.*' -print)"; }

for mode in symlink directory; do
    export CATALYST_PUBLISH_MODE="$mode"
    rm -rf -- "$FIXTURE/dist" "$FIXTURE/.catalyst"
    printf '# Stable chapter\n' > "$FIXTURE/docs/01.md"
    cli all >/dev/null
    before=$(snapshot)
    printf '\n[Broken](missing-file.md)\n' >> "$FIXTURE/docs/01.md"
    reject cli all
    test "$before" = "$(snapshot)"
    assert_no_staging
    printf '# Stable chapter\n' > "$FIXTURE/docs/01.md"

    # Uma falha no modulo real precisa interromper a CLI, sem publicar.
    sed -i '/^validate_assets_and_links() {/a\    return 77' "$FIXTURE/scripts/core/validator.sh"
    reject cli build
    test "$before" = "$(snapshot)"
    cp "$ROOT/scripts/core/validator.sh" "$FIXTURE/scripts/core/validator.sh"

    # Outra execucao aguarda o mesmo lock e nao toca na publicacao enquanto espera.
    exec 7>"$FIXTURE/.catalyst/build.lock"
    flock -x 7
    printf '# New chapter\n' > "$FIXTURE/docs/01.md"
    cli all 7>&- > "$FIXTURE/writer.log" 2>&1 &
    writer=$!
    sleep 0.2
    kill -0 "$writer"
    test "$before" = "$(snapshot)"
    flock -u 7
    wait "$writer"
    grep -q 'New chapter' "$FIXTURE/dist/docs/full-document.md"

    # Dois escritores de verdade concluem sem mesclar geracoes ou pacotes.
    cli all > "$FIXTURE/first.log" 2>&1 & first=$!
    cli all > "$FIXTURE/second.log" 2>&1 & second=$!
    wait "$first"
    wait "$second"
    (cd "$FIXTURE/dist/releases" && sha256sum -c ./*.sha256) >/dev/null
    assert_no_staging

    # O preview le a geracao atual, sem fixar o destino antigo do symlink.
    port=$((20000 + RANDOM % 20000))
    while nc -z -w 1 127.0.0.1 "$port"; do port=$((20000 + RANDOM % 20000)); done
    cli serve --port "$port" >/dev/null
    exec 6>"$FIXTURE/.catalyst/publish.lock"
    flock -x 6
    curl --silent --show-error --retry 3 --retry-connrefused --max-time 5 "http://127.0.0.1:$port/docs/full-document.md" 6>&- > "$FIXTURE/reader-output" &
    reader=$!
    sleep 0.2
    kill -0 "$reader"
    test ! -s "$FIXTURE/reader-output"
    flock -u 6
    wait "$reader"
    grep -q 'New chapter' "$FIXTURE/reader-output"
    printf '# HTTP new generation\n' > "$FIXTURE/docs/01.md"
    cli build >/dev/null
    curl --silent --show-error --retry 3 --retry-connrefused --max-time 5 "http://127.0.0.1:$port/docs/full-document.md" > "$FIXTURE/new-output"
    grep -q 'HTTP new generation' "$FIXTURE/new-output"
    if [ "$mode" = directory ]; then
        # Journal persistente: o leitor restaura a ultima versao apos uma queda.
        mkdir "$FIXTURE/.catalyst/previous"
        cp -a "$FIXTURE/dist/." "$FIXTURE/.catalyst/previous/"
        cp "$FIXTURE/dist/metrics/metrics.txt" "$FIXTURE/expected-metrics"
        touch "$FIXTURE/.catalyst/in-progress"
        printf 'interrupted publication' > "$FIXTURE/dist/metrics/metrics.txt"
        curl --silent --show-error --retry 3 --retry-connrefused --max-time 5 "http://127.0.0.1:$port/metrics/metrics.txt" > "$FIXTURE/recovered-metrics"
        cmp "$FIXTURE/expected-metrics" "$FIXTURE/recovered-metrics"
        test ! -f "$FIXTURE/.catalyst/in-progress"
    fi
    cli serve --stop >/dev/null

    # Interrupcao durante o processamento deixa a publicacao anterior intacta.
    before=$(snapshot)
    cat > "$FIXTURE/wrappers/sed" <<'WRAPPER'
#!/usr/bin/env bash
touch "$CATALYST_TEST_READY"
exec /usr/bin/sleep 30
WRAPPER
    chmod +x "$FIXTURE/wrappers/sed"
    setsid env PATH="$FIXTURE/wrappers:$PATH" CATALYST_TEST_READY="$FIXTURE/ready" bash "$FIXTURE/catalyst.sh" build > "$FIXTURE/interrupted.log" 2>&1 &
    interrupted=$!
    for _ in {1..100}; do [ ! -f "$FIXTURE/ready" ] || break; sleep 0.05; done
    test -f "$FIXTURE/ready"
    kill -TERM -- "-$interrupted"
    if wait "$interrupted"; then echo 'Build interrompido retornou sucesso' >&2; exit 1; fi
    for _ in {1..100}; do
        [ -n "$(find "$FIXTURE/.catalyst" -maxdepth 1 -name 'stage.*' -print)" ] || break
        sleep 0.05
    done
    test "$before" = "$(snapshot)"
    assert_no_staging
    rm -f "$FIXTURE/wrappers/sed" "$FIXTURE/ready"

    if [ "$mode" = symlink ]; then
        # Sinal logo apos o commit nao pode apagar a geracao recem-publicada.
        cat > "$FIXTURE/wrappers/mv" <<'WRAPPER'
#!/usr/bin/env bash
target="${!#}"
/usr/bin/mv "$@" || exit $?
if [[ "$target" == */dist ]]; then kill -TERM "$PPID"; fi
WRAPPER
        chmod +x "$FIXTURE/wrappers/mv"
        reject env PATH="$FIXTURE/wrappers:$PATH" bash "$FIXTURE/catalyst.sh" all
        test -s "$FIXTURE/dist/docs/full-document.md"
        (cd "$FIXTURE/dist/releases" && sha256sum -c ./*.sha256) >/dev/null
        rm -f "$FIXTURE/wrappers/mv"
    fi

    if [ "$mode" = directory ]; then
        # Falha no commit, apos mudar arquivos: o journal deve restaurar o snapshot.
        cat > "$FIXTURE/wrappers/mv" <<'WRAPPER'
#!/usr/bin/env bash
target="${!#}"
if [[ "$target" == */dist/index.html ]] && [ ! -f "$CATALYST_TEST_FAIL" ]; then
    touch "$CATALYST_TEST_FAIL"
    exit 73
fi
exec /usr/bin/mv "$@"
WRAPPER
        chmod +x "$FIXTURE/wrappers/mv"
        printf '\n<!-- new template -->\n' >> "$FIXTURE/templates/index.html"
        printf '# Unpublished chapter\n' > "$FIXTURE/docs/01.md"
        reject env PATH="$FIXTURE/wrappers:$PATH" CATALYST_TEST_FAIL="$FIXTURE/failed-once" bash "$FIXTURE/catalyst.sh" all
        test -f "$FIXTURE/failed-once"
        test "$before" = "$(snapshot)"
        test ! -f "$FIXTURE/.catalyst/in-progress"
        assert_no_staging
        rm -f "$FIXTURE/wrappers/mv"
    fi
    echo "Transacoes $mode: falhas, bloqueio, concorrencia, preview, recuperacao e interrupcao aprovados."
done
