#!/usr/bin/env bash
# Mesmo ponto de entrada para validacao local e GitHub Actions.
set -eo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
command -v shellcheck >/dev/null || { echo 'Instale shellcheck antes de executar este check.' >&2; exit 1; }
mapfile -d '' -t scripts < <(find scripts -type f \( -name '*.sh' -o -name '*.bash' \) -print0 | sort -z)
scripts=(catalyst.sh "${scripts[@]}")
for script in "${scripts[@]}"; do bash -n "$script"; done
shellcheck --external-sources --severity=style "${scripts[@]}"
bash catalyst.sh test
bash catalyst.sh all
bash catalyst.sh report
bash catalyst.sh pack
(cd dist/releases && sha256sum -c ./*.sha256)
