#!/usr/bin/env bash
# Os trechos abaixo sao texto literal do fonte, nunca comandos a expandir.
# shellcheck disable=SC2016
# Relatorio reproduzivel: referencias resolvidas a partir do codigo atual.
set -eo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
OUT="${1:-$ROOT/dist/reports/sigaa-report.md}"
mkdir -p "$(dirname "$OUT")"
TMP=$(mktemp "${OUT}.tmp.XXXXXXXX")
trap 'rm -f "$TMP"' EXIT

concept() {
    local id="$1" lesson="$2" file="$3" snippet="$4" description="$5" line escaped
    line=$(NEEDLE="$snippet" awk 'BEGIN {needle=ENVIRON["NEEDLE"]} index($0, needle) && $0 !~ /^[[:space:]]*#/ {print NR; exit}' "$ROOT/$file")
    [ -n "$line" ] || { echo "Conceito $id sem evidencia: $file / $snippet" >&2; exit 1; }
    escaped=${snippet//|/&#124;}
    printf '| %02d | %s | %s | %s | `%s` (%s) | %s |\n' "$((10#$id))" "$id" "$lesson" "$line" "$escaped" "$file" "$description"
}

{
    cat <<'INTRO'
# Relatorio academico - Catalyst Shell Engine

Instituicao: CEFET-MG - Engenharia da Computacao

Disciplina: TEFC: Shell Scripting - 2026/2

Aluno: Matheus Thiago de Souza Ferreira

## 1. Problema e solucao

A documentacao tecnica fragmentada em varios arquivos Markdown dificulta a leitura,
a navegacao e a identificacao de referencias quebradas. O Catalyst Shell Engine
automatiza a consolidacao dos capitulos, a normalizacao de texto, a geracao de
sumario, a verificacao de arquivos referenciados, as metricas e o empacotamento.

A entrada externa consiste nos arquivos docs/*.md e nos ativos locais. As saidas
sao documento consolidado, sumario, metricas, interface HTML e pacote tar.gz com
checksums. A CLI recebe argumentos; os comandos read existentes consomem arquivos,
pipes ou requisicoes HTTP, sem solicitar dados do teclado.

O nucleo e Bash com modulos de parser, sanitizacao, validacao, empacotamento e transacoes.
Cada build usa staging privado e flock antes da publicacao. Em filesystem Linux,
um link dist aponta atomicamente para a geracao concluida. Em DrvFS, a troca de
arquivos e coordenada por lock e journal para manter compatibilidade Windows.
A interface gerada contem HTML, CSS e
JavaScript com Marked, DOMPurify e Mermaid locais, sem CDN. O preview padrao usa
Bash e netcat; --backend threaded usa Python padrao com multiplas threads. Ambos
escutam somente em 127.0.0.1 e respeitam o bloqueio de publicacao.

Este texto deve corresponder ao problema efetivamente enviado a lista da disciplina;
a existencia deste relatorio nao comprova o envio da Etapa 01.

## 2. Planilha de conceitos

As referencias abaixo sao calculadas na geracao. Os arquivos citados aparecem
integralmente, com numeracao independente, na secao de codigo. Os 20 conceitos
distintos incluem os 15 solicitados no enunciado.

| # | Conceito | Aula | Linha | Trecho de Codigo | Descricao |
|---|---|---|---|---|---|
INTRO
    concept 01 'Comandos basicos' catalyst.sh 'echo " Data do Sistema:' 'echo e date exibem a data da execucao.'
    concept 02 'Processamento de texto' catalyst.sh 'TOTAL_LINES=$(wc -l' 'wc conta as linhas do documento.'
    concept 03 'Sistema de arquivos' scripts/core/packager.sh 'tar -czf "$output_archive"' 'tar compacta os artefatos em gzip.'
    concept 04 'Sistema de arquivos' catalyst.sh 'chmod 755 "$DIST_DIR"' 'chmod aplica permissoes octais ao diretorio.'
    concept 05 'Processos' scripts/core/server.sh 'ps -p "$pid"' 'ps verifica a existencia do processo registrado.'
    concept 06 'Processos' scripts/core/server.sh 'kill -15 -- "-$pid"' 'SIGTERM encerra o grupo de processos do preview.'
    concept 07 'Entradas, saidas e Redirecionamentos' catalyst.sh '> "$METRICS_FILE"' 'Redirecionamento grava o relatorio de metricas.'
    concept 08 'Entradas, saidas e Redirecionamentos' scripts/core/parser.sh 'done < <(find' 'Pipe ordena arquivos; substituicao de processo alimenta o laco.'
    concept 09 'Expansoes' scripts/core/parser.sh 'TOTAL_DOCS=$((TOTAL_DOCS + 1))' 'Expansao aritmetica incrementa o contador.'
    concept 10 'Parametros e Variaveis' catalyst.sh 'DIST_DIR="$PUBLISHED_DIR"' 'Variavel criada pelo usuario define a pasta de saida.'
    concept 11 'Parametros e Variaveis' scripts/core/server.sh 'local server_pid=$!' 'Parametro especial captura o PID do processo em background.'
    concept 12 'Parametros e Variaveis' catalyst.sh 'readonly APP_NAME=' 'readonly impede reatribuicao da constante.'
    concept 13 'Parametros e Variaveis' catalyst.sh 'COMMAND="${1:-help}"' 'Expansao avancada define help como valor padrao.'
    concept 14 'Estruturas de fluxo condicionais' scripts/core/parser.sh 'if [ -f "$doc" ]; then' 'Teste -f seleciona arquivos regulares.'
    concept 15 'Estruturas de fluxo condicionais' catalyst.sh 'case "$COMMAND" in' 'case seleciona a operacao da CLI.'
    concept 16 'Estruturas de fluxo condicionais' scripts/core/parser.sh '[ $TOTAL_DOCS -gt 0 ] &&' 'Operador AND condiciona a exibicao do total.'
    concept 17 'Estruturas de fluxo de repeticao' scripts/core/parser.sh "while IFS= read -r -d '' doc; do" 'while percorre nomes delimitados por NUL, sem entrada do teclado.'
    concept 18 'Expressoes Regulares' scripts/core/validator.sh 'grep -E' 'Regex estendida com classe POSIX identifica erros de referencias no indice.'
    concept 19 sed scripts/core/sanitizer.sh 'sed -e' 'Programa sed normaliza CRLF sem alterar os blocos de codigo.'
    concept 20 AWK scripts/core/markdown.awk 'function heading(' 'Programa GNU AWK indexa titulos e calcula IDs unicos e referencias por capitulo.'
    printf '\n## 3. Verificacao de linhas com cloc\n\n'
    command -v cloc >/dev/null || { echo 'Instale cloc para gerar a evidencia obrigatoria.' >&2; exit 1; }
    printf 'Comando: `cloc catalyst.sh scripts/core/*.{sh,awk,py} scripts/academic-report.sh`\n\n```text\n'
    cloc --quiet "$ROOT/catalyst.sh" "$ROOT"/scripts/core/*.{sh,awk,py} "$ROOT/scripts/academic-report.sh"
    printf '```\n\nA contagem e produzida pela ferramenta, sem reutilizar valores historicos.\n'
    printf '\n## 4. Codigo-fonte numerado\n'
    for file in catalyst.sh scripts/core/*.{sh,awk,py} scripts/academic-report.sh; do
        language=bash
        case "$file" in *.awk) language='awk' ;; *.py) language=python ;; esac
        printf '\n### %s\n\n```%s\n' "$file" "$language"
        nl -ba -w 4 -s ': ' "$ROOT/$file"
        printf '```\n'
    done
    printf '\n## 5. Geracao do relatorio\n\n'
    printf 'Gerado em: %s.\n' "$(date -Iseconds)"
    printf 'Apoio a entrega: scripts/academic-report.sh. O exportador PDF opcional e separado do nucleo avaliado.\n'
} > "$TMP"
mv "$TMP" "$OUT"
echo "Relatorio atualizado: $OUT"
