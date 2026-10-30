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
gawk -v mode=index -v chapter_list=/dev/null -v file_list=/dev/null -f scripts/core/markdown.awk /dev/null
gawk -v json=/dev/null -f scripts/core/toc.awk /dev/null >/dev/null
NODE_CMD="node"
command -v node >/dev/null 2>&1 || NODE_CMD="node.exe"
"$NODE_CMD" --check templates/app.js
python3 -m py_compile scripts/core/server-threaded.py scripts/tests/http_backends.py scripts/tests/configuration.py scripts/tests/reproducibility.py
gawk -f scripts/core/validation-report.awk /dev/null >/dev/null
bash catalyst.sh test
bash catalyst.sh all
bash catalyst.sh report
bash catalyst.sh pack
(cd dist/releases && sha256sum -c ./*.sha256)
npm test -- --project
npm run test:browser -- --project
