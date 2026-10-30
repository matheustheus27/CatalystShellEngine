#!/usr/bin/env bash
# Uma copia temporaria mantem a demonstracao separada dos capitulos reais.
set -eo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK=$(mktemp -d /tmp/catalyst-demo.XXXXXXXX)
trap 'rm -rf -- "$WORK"' EXIT
cp -R "$ROOT/examples/demo/." "$WORK/"
cli() { bash "$ROOT/catalyst.sh" "$@" --docs "$WORK/docs" --output "$WORK/site"; }
snapshot() { (cd "$WORK/site" && find . -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum); }
echo '1/4 Publicando os capitulos validos, os titulos repetidos e os ativos...'
cli all > "$WORK/build.log" 2>&1 || { cat "$WORK/build.log"; exit 1; }
head -n 16 "$WORK/site/docs/summary.md"
before=$(snapshot)
cp "$WORK/invalid/99-link-quebrado.md" "$WORK/docs/"
echo '2/4 Introduzindo referencias invalidas; validate e all devem falhar...'
for command in validate all; do
    if cli "$command" > "$WORK/invalid.log" 2>&1; then
        echo "Falha: $command aceitou referencias invalidas." >&2; exit 1
    fi
    [ "$before" = "$(snapshot)" ] || { echo 'Publicacao foi alterada indevidamente.' >&2; exit 1; }
done
echo '3/4 Conferindo a auditoria e a preservacao integral da publicacao...'
grep -q 'REPROVADO' "$WORK/site.validation.md"
grep -q 'arquivo-ausente.md' "$WORK/site.validation.md"
grep -q 'Ancora inexistente' "$WORK/site.validation.md"
cat "$WORK/site.validation.md"
rm "$WORK/docs/99-link-quebrado.md"
echo '4/4 Removendo a falha da copia e validando novamente...'
cli validate > "$WORK/valid.log" 2>&1 || { cat "$WORK/valid.log"; exit 1; }
grep -q 'APROVADO' "$WORK/site.validation.md"
echo 'Demonstracao aprovada: ordenacao, sumario, ativos, auditoria e rollback.'
