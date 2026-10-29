# 03. Conformidade com o Enunciado (20 Conceitos)

## Visão Geral da Matriz de Conceitos

O enunciado do **Trabalho Prático - TEFC: Shell Scripting** estabelece 20 conceitos fundamentais de desenvolvimento em ambiente Unix/Bash, exigindo a utilização comprovada de no mínimo 15 conceitos em um script com pelo menos 30 linhas de código.

O **Catalyst Shell Engine** demonstra os 20 conceitos do enunciado considerando o script principal e o módulo de servidor. A planilha gerada por `report` é a referência para arquivos e linhas atuais; a contagem de código vem da execução real do `cloc`.

Abaixo, cada conceito é dissecado teoricamente com sua respectiva aplicação prática no código-fonte de [`catalyst.sh`](#04manualoperacionaldacli).

---

## Detalhamento Conceitual por Aula

### 01. Comandos Básicos (Aula: Comandos básicos)
- **Conceitos**: `echo, ls, pwd, cd, tree, find, locate, whereis, file, stat, date, cal, history, clear, logout ou exit`
- **Aplicação no Projeto**:
  * `date`: Utilizado em cabeçalhos de execução e no relatório de métricas para carimbar o instante preciso da compilação: `date '+%d/%m/%Y %H:%M:%S'`.
  * `echo`: Usado para saída informativa estruturada e formatação no terminal.
  * `cd` e `pwd`: Empregados na resolução canônica e dinâmica do diretório-base do script: `BASE_DIR="$(cd "$(dirname "$0")" && pwd)"`.
  * `exit`: Saída limpa do script com códigos de status padronizados (0 para sucesso, 1 para falha).

### 02. Processamento de Texto (Aula: Processamento de texto)
- **Conceitos**: `strings, cat, tac, wc, more, less, head, tail, tee, sort, zcat ou diff`
- **Aplicação no Projeto**:
  * `wc -l` e `wc -w`: Computam com precisão cirúrgica a contagem de linhas e palavras no documento mestre unificado (`TOTAL_LINES=$(wc -l < "$OUTPUT_DOC")`).
  * `cat`: Utilizado para concatenar capítulos Markdown e exibir relatórios de integridade.
  * `sort -V`: Ordenação de versão/numérica natural dos arquivos em `docs/*.md`, garantindo que `02-architecture.md` venha antes de `10-apendice.md`.
  * `head -n 3` e `tail -n 3`: Amostragem dos blocos de abertura e conclusão do documento para o arquivo `metrics.txt`.

### 03. Sistema de Arquivos (Aula: Sistema de arquivos)
- **Conceitos**: `mkdir, cd, rmdir, mv, cp, mv, ln, id, umask, basename, dirname, gzip, gunzip, tar, split, shred, cksum, md5sum, dd, lsof ou fuser`
- **Aplicação no Projeto**:
  * `mkdir -p`: Criação recursiva e idempotente da pasta `dist/`.
  * `basename` e `dirname`: Extração de nomes de arquivos e caminhos de diretórios pais.
  * `tar` e `gzip`: Empacotamento compactado do bundle final de distribuição: `tar -czf "$OUTPUT_BUNDLE" -C "$DIST_DIR" ...`.
  * `md5sum` (com fallback em `cksum`): Checksum adicional de compatibilidade; SHA-256 é o checksum principal do release.
  * O servidor verifica portas ocupadas sem encerrar processos de terceiros.

### 04. Permissões de Arquivos (Aula: Sistema de arquivos)
- **Conceitos**: `chmod` (representação octal ou simbólica)
- **Aplicação no Projeto**:
  * **Representação Octal**: `chmod 755 "$DIST_DIR"`, garantindo que o diretório de publicação tenha permissões explícitas de leitura, escrita e execução para o dono, e leitura/execução para os demais usuários.
  * **Representação Simbólica**: `chmod u=rw,go=r "$OUTPUT_BUNDLE"`, assegurando que o tarball de release seja gravável apenas pelo autor e legível universalmente.

### 05. Controle de Processos (Aula: Processos)
- **Conceitos**: `ps, top, jobs, bg, fg, pstree, vmstat, xload ou tload`
- **Aplicação no Projeto**:
  * `ps -p "$pid"`: Inspeciona a tabela de processos do kernel para checar se o servidor web HTTP local continua vivo antes de encerrá-lo ou emitir alertas.
  * O código do gerenciamento de processos está em `scripts/core/server.sh`.

### 06. Sinais do Sistema Operacional (Aula: Processos)
- **Conceitos**: `kill ou killall`
- **Aplicação no Projeto**:
  * `kill -15 -- "-$pid"`: Envio do sinal padrão `SIGTERM` para encerramento gracioso do servidor web.
  * `kill -9 -- "-$pid"`: Fallback imediato com `SIGKILL` caso o processo não responda ao término gracioso dentro do timeout.

### 07. Redirecionamentos de Entrada e Saída (Aula: Entradas, saídas e Redirecionamentos)
- **Conceitos**: Redirecionamento da entrada (`<`), saída (`>`), saída de adição (`>>`) e saída de erro padrão (`2>`, `>&2`)
- **Aplicação no Projeto**:
  * `> "$METRICS_FILE"`: Gravação do relatório calculado; a inicialização preserva métricas existentes.
  * `echo "..." >&2`: Emissão de mensagens de diagnóstico na saída de erro padrão (*stderr*).
  * `2>/dev/null`: Supressão de mensagens de erro irrelevantes durante varreduras silenciosas.
  * `wc -l < "$OUTPUT_DOC"`: Alimentação direta da entrada padrão (*stdin*) do `wc` para evitar a impressão do nome do arquivo.

### 08. Pipes e Redirecionamentos Avançados (Aula: Entradas, saídas e Redirecionamentos)
- **Conceitos**: Pipes (`|`), redirecionamentos compostos e *Process Substitution* (`<(...)`)
- **Aplicação no Projeto**:
  * Pipe linear com ordenação: `ls "$DOCS_DIR"/*.md 2>/dev/null | sort -V`.
  * Redirecionamento avançado em bloco: `{ echo "..."; echo "..."; } > "$METRICS_FILE"`.
  * *Process Substitution*: `while IFS= read -r match; do ... done < <(grep -E -o "$link_pattern" "$OUTPUT_DOC")`, alimentando o laço `while` sem criar subshell isolada para as variáveis acumuladoras.

### 09. Expansões do Shell (Aula: Expansões)
- **Conceitos**: Expansão de arquivos, til (`~`), aritmética (`$((...))`), chaves (`{...}`), parâmetros e substituição de comandos (`$(...)`)
- **Aplicação no Projeto**:
  * Expansão aritmética: `TOTAL_DOCS=$((TOTAL_DOCS + 1))` e `broken_links=$((broken_links + 1))`.
  * Substituição de comando: `BASE_DIR="$(cd "$(dirname "$0")" && pwd)"`.
  * Expansão de caminhos e globbing: `"$DOCS_DIR"/*.md`.

### 10. Variáveis de Usuário e Reservadas (Aula: Parâmetros e Variáveis)
- **Conceitos**: Declaração, manipulação e escopo de variáveis
- **Aplicação no Projeto**:
  * Definição de caminhos absolutos canônicos: `DIST_DIR="${BASE_DIR}/dist"`, `OUTPUT_DOC="${DIST_DIR}/full-document.md"`.
  * Uso de variáveis de ambiente do sistema (`PATH`, `USER`).

### 11. Parâmetros Posicionais e Especiais (Aula: Parâmetros e Variáveis)
- **Conceitos**: `$0 até $n, $*, $@, $#, $?, $$ ou $!`
- **Aplicação no Projeto**:
  * `$0`: Identificador do nome do script invocado para mensagens de ajuda e uso.
  * `$1`, `$2`: Captura dos subcomandos principais na CLI (`build`, `validate`, `serve`).
  * `$#`: Verificação da contagem total de argumentos passados.
  * `$@`: Repasse transparente de listas completas de flags e opções para funções internas (`manage_server "$@"`).
  * `$!`: Captura do Process ID (PID) exato do processo lançado em segundo plano (`setsid bash "$SCRIPT" worker ... &`).
  * `$?`: Captura e propagação do código de retorno da última operação (`exit $?`).

### 12. Atributos de Variáveis (Aula: Parâmetros e Variáveis)
- **Conceitos**: `readonly`, `export`, inteira (`declare -i`), arranjo (`declare -a`) e funções
- **Aplicação no Projeto**:
  * `readonly APP_NAME="Catalyst Shell Engine"`: Imutabilidade de constantes essenciais.
  * `export CATALYST_ENV="production"`: Exportação global para processos filhos.
  * `declare -i TOTAL_DOCS=0`: Declaração explícita de variáveis inteiras tipadas.
  * `declare -a CHAPTER_FILES=()`: Array indexado para armazenar a lista de capítulos processados.
  * Declaração de funções modulares estruturadas (`init_env()`, `consolidate_docs()`, etc.).

### 13. Expansões Avançadas de Parâmetros (Aula: Parâmetros e Variáveis)
- **Conceitos**: `${param:-default}, ${param:=val}, ${param%%pattern}, ${param#pattern}, ${param//pattern/string}`
- **Aplicação no Projeto**:
  * Valor padrão (*fallback*): `COMMAND="${1:-help}"` e `port="${1:-8000}"`.
  * Remoção do maior sufixo coincidente: `clean_target="${raw_url%%#*}"` para descartar âncoras internas de links Markdown.
  * Expansão com verificação de não-nulo: `rm -rf "${DIST_DIR:?}"/*` para proteção contra deleções acidentais de diretórios raiz.

### 14. Testes Condicionais com Test e If (Aula: Estruturas de fluxo condicionais)
- **Conceitos**: Operadores `-f`, `-d`, `-z`, `-n`, `=~` (regex nativo)
- **Aplicação no Projeto**:
  * Verificação de arquivo regular: `if [ -f "$doc" ]; then`.
  * Verificação de diretório: `if [ -d "$target_path" ]; then`.
  * Comparação com Regex nativo do Bash: `if [[ ! "$raw_url" =~ ^https?:// && ! "$raw_url" =~ ^# ]]; then`.

### 15. Estruturas de Seleção Case (Aula: Estruturas de fluxo condicionais)
- **Conceitos**: `case ... in ... esac` com correspondência de padrões
- **Aplicação no Projeto**:
  * Roteador central da CLI de subcomandos:
    ```bash
    case "$COMMAND" in
        build)    ... ;;
        validate) ... ;;
        serve)    ... ;;
        clean)    ... ;;
        *)        ... ;;
    esac
    ```

### 16. Desvios Condicionais com Operadores Lógicos (Aula: Estruturas de fluxo condicionais)
- **Conceitos**: Operadores `&&` (AND lógico) e `||` (OR lógico)
- **Aplicação no Projeto**:
  * Proteção contra falhas em etapas críticas: `mkdir -p "$DIST_DIR" || { echo "Falha..." >&2; exit 1; }`.
  * Execução condicional concisa: `[ $TOTAL_DOCS -gt 0 ] && echo "Total de capitulos: $TOTAL_DOCS"`.

### 17. Comandos de Repetição e Sequenciadores (Aula: Estruturas de fluxo de repetição)
- **Conceitos**: `for, while, until, select, break, continue`
- **Aplicação no Projeto**:
  * Laço `for`: Iteração ordenada sobre o resultado de globbing e ordenação de capítulos.
  * Laço `while`: Processamento linha por linha dos resultados do validador de links.
  * `continue`: Salto de iterações em linhas vazias detectadas durante a auditoria.

### 18. Expressões Regulares Básicas e Estendidas (Aula: Expressões Regulares)
- **Conceitos**: `grep` e `egrep` / `grep -E` utilizando metacaracteres obrigatórios
- **Aplicação no Projeto**:
  * Expressão regular estendida com metacaracteres `^`, `!`, `\[`, `\]`, `+`, `(`, `)`:
    `grep -E -o '\[[^]]+\]\(([^)]+)\)' "$OUTPUT_DOC"`
  * Extração e auditoria rigorosa de todas as referências a links e imagens locais.

### 19. Programa em Sed (Aula: sed)
- **Conceitos**: Comandos de edição, substituição e scripts com expressões regulares
- **Aplicação no Projeto**:
  * Higienização e normalização léxica de todos os documentos unificados:
    ```bash
    sed -E \
        -e 's/[ \t]+$//' \
        -e 's/^(#+)[ \t]+/\1 /' \
        "$temp_concat" > "$OUTPUT_DOC"
    ```
  * Remoção de espaços finais de linha e garantia de espaçamento padronizado em títulos Markdown.

### 20. Programa em AWK (Aula: AWK)
- **Conceitos**: Blocos `BEGIN`, padrões condicionais, variáveis associativas e formatação de saída
- **Aplicação no Projeto**:
  * Motor analítico completo de geração de sumário (TOC):
    ```awk
    BEGIN {
        h1 = 0; h2 = 0; h3 = 0;
    }
    /^# [^#]/ {
        h1++; h2 = 0; h3 = 0;
        title = substr($0, 3);
        anchor = tolower(title);
        gsub(/[^a-z0-9_-]/, "", anchor);
        printf("%d. [%s](#%s)\n", h1, title, anchor);
    }
    /^## [^#]/ {
        h2++; h3 = 0;
        title = substr($0, 4);
        anchor = tolower(title);
        gsub(/[^a-z0-9_-]/, "", anchor);
        printf("   %d.%d. [%s](#%s)\n", h1, h2, title, anchor);
    }
    /^### [^#]/ {
        h3++;
        title = substr($0, 5);
        anchor = tolower(title);
        gsub(/[^a-z0-9_-]/, "", anchor);
        printf("      %d.%d.%d. [%s](#%s)\n", h1, h2, h3, title, anchor);
    }
    ```
  * Identificação de níveis de títulos, cálculo autônomo da numeração decimal hierárquica e conversão para âncoras navegáveis consistentes com a interface HTML gerada.
