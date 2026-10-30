#!/usr/bin/env bash
set -eo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURE=$(mktemp -d /tmp/catalyst-regression.XXXXXXXX)
cleanup() {
    bash "$FIXTURE/catalyst.sh" serve --stop >/dev/null 2>&1 || true
    rm -rf -- "$FIXTURE"
}
trap cleanup EXIT
cp "$ROOT/catalyst.sh" "$FIXTURE/"
cp -R "$ROOT/scripts" "$ROOT/images" "$ROOT/templates" "$ROOT/vendor" "$FIXTURE/"
mkdir "$FIXTURE/docs"
cli() { bash "$FIXTURE/catalyst.sh" "$@"; }
reject() { if "$@" >/dev/null 2>&1; then echo "Aceitou entrada invalida: $*" >&2; exit 1; fi; }

reject cli build
cat > "$FIXTURE/docs/01 chapter with spaces.md" <<'DOC'
# First chapter

[Valid anchor](#firstchapter)

![Local asset](images/logo.svg)

    ```bash
    [Example, not a link](missing-example.md)
    ```
DOC
cli all >/dev/null
grep -q 'First chapter' "$FIXTURE/dist/docs/full-document.md"
test -s "$FIXTURE/dist/assets/logo.svg"
cp "$FIXTURE/dist/metrics/metrics.txt" "$FIXTURE/metrics-before"
cli pack >/dev/null
cmp "$FIXTURE/metrics-before" "$FIXTURE/dist/metrics/metrics.txt"
(cd "$FIXTURE/dist/releases" && sha256sum -c ./*.sha256) >/dev/null

printf '\n[Broken](missing-file.md)\n' >> "$FIXTURE/docs/01 chapter with spaces.md"
reject cli build
reject cli validate
reject cli all
sed -i '/\[Broken\]/d' "$FIXTURE/docs/01 chapter with spaces.md"
printf '\n[Broken anchor](#missing-anchor)\n' >> "$FIXTURE/docs/01 chapter with spaces.md"
reject cli build
reject cli validate
sed -i '/\[Broken anchor\]/d' "$FIXTURE/docs/01 chapter with spaces.md"
cli all >/dev/null
reject cli serve --port 0
reject cli serve --port 65536
reject cli serve --port 123abc
reject cli serve --port
reject cli unknown-command

PORT=$((20000 + RANDOM % 20000))
while nc -z -w 1 127.0.0.1 "$PORT"; do PORT=$((20000 + RANDOM % 20000)); done
cli serve --port "$PORT" >/dev/null
http_code() {
    curl --silent --show-error --retry 3 --retry-connrefused --max-time 5 --path-as-is -o /dev/null -w '%{http_code}' "$@"
}
expect_http() {
    local expected="$1" actual
    shift
    actual=$(http_code "$@") || return 1
    test "$actual" = "$expected"
}
expect_http 200 "http://127.0.0.1:$PORT/"
expect_http 200 --head "http://127.0.0.1:$PORT/assets/logo.svg"
expect_http 404 "http://127.0.0.1:$PORT/missing"
expect_http 403 "http://127.0.0.1:$PORT/../catalyst.sh"
ln -s "$FIXTURE/catalyst.sh" "$FIXTURE/dist/outside-link"
expect_http 403 "http://127.0.0.1:$PORT/outside-link"
expect_http 405 -X POST "http://127.0.0.1:$PORT/"
cli serve --restart >/dev/null
expect_http 200 "http://127.0.0.1:$PORT/"
cli serve --stop >/dev/null
if nc -z -w 1 127.0.0.1 "$PORT"; then echo 'Porta ficou aberta apos stop' >&2; exit 1; fi
cli report >/dev/null
test "$(grep -c '^| [0-9]' "$FIXTURE/dist/reports/sigaa-report.md")" -eq 20
test "$(awk '/^## 4[.] Codigo/ {sources=1; next} /^## 5[.]/ {sources=0} sources && /^```bash/ {count++} END {print count+0}' "$FIXTURE/dist/reports/sigaa-report.md")" -eq "$(find "$FIXTURE/scripts/core" -maxdepth 1 -name '*.sh' | wc -l | awk '{print $1+2}')"
echo 'Regressoes: arquivos com espacos, vazio, links, metricas, SHA-256, HTTP, isolamento e relatorio aprovados.'
