#!/usr/bin/env bash
set -eo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURE=$(mktemp -d /tmp/catalyst-integration.XXXXXXXX)
cleanup() {
    bash "$FIXTURE/catalyst.sh" serve --stop >/dev/null 2>&1 || true
    rm -rf -- "$FIXTURE"
}
trap cleanup EXIT
cp "$ROOT/catalyst.sh" "$FIXTURE/"
cp -R "$ROOT/scripts" "$ROOT/docs" "$ROOT/images" "$ROOT/templates" "$FIXTURE/"
cli() { bash "$FIXTURE/catalyst.sh" "$@"; }
assert() {
    local name="$1"
    shift
    printf 'Teste: %s... ' "$name"
    "$@"
    echo 'OK'
}
assert 'pipeline completo pela CLI e modulos reais' cli all
assert 'permissoes da geracao' test "$(stat -Lc %a "$FIXTURE/dist")" = 755
assert 'sumario nao vazio' test -s "$FIXTURE/dist/docs/summary.md"
assert 'metricas nao vazias' test -s "$FIXTURE/dist/metrics/metrics.txt"
assert 'imagem publicada' test -s "$FIXTURE/dist/assets/logo.svg"
# A expansao de $1 e feita pelo bash filho.
# shellcheck disable=SC2016
assert 'checksum SHA-256' bash -c 'cd "$1" && sha256sum -c ./*.sha256' _ "$FIXTURE/dist/releases"
# shellcheck disable=SC2016
assert 'pacote inclui HTML' bash -c 'tar -tzf "$1" | grep -Fx index.html' _ "$FIXTURE/dist/releases/catalyst-release-1.0.0.tar.gz"
assert 'relatorio com fontes modulares' cli report
assert 'regressoes de CLI e HTTP' bash "$ROOT/scripts/tests/regression.sh"
assert 'transacoes, interrupcoes e concorrencia' bash "$ROOT/scripts/tests/transaction.sh"
echo 'Integracao, regressoes e transacoes aprovadas.'
