# 03. Conformidade com o Enunciado (20 Conceitos)

## Evidências e contagem

O enunciado solicita pelo menos 30 linhas de código Shell verificadas por `cloc` e ao menos 15 conceitos distintos. O projeto documenta vinte conceitos da CLI e dos módulos executados. Cada item abaixo apresenta uma aplicação real, não é uma lista de comandos que o programa deveria usar.

A referência oficial de arquivo e linha é `dist/reports/sigaa-report.md`, produzido por `./catalyst.sh report`. O gerador procura os trechos nos fontes atuais, falha se uma evidência desaparecer, executa `cloc` e inclui o código integral numerado por `nl -ba`. A planilha possui as seis colunas do enunciado. A saída do cloc discrimina Shell, AWK e Python, a categoria Shell deve ser examinada para o mínimo exigido.

Os usos de `read` documentados recebem arquivos, pipes e HTTP, sem entrada pelo teclado. A [entrega acadêmica](../CEFET_REPORT.md) explica a exportação e a revisão final.

## Conceitos aplicados

### 01. Comandos básicos

Em `catalyst.sh`, `echo` e `date` mostram a data da execução. `cd` e `pwd` determinam o diretório-base do projeto a partir da localização do script, permitindo chamá-lo de outro diretório.

### 02. Processamento de texto

`compute_statistics`, em `catalyst.sh`, usa `wc -l` e `wc -w` para contar linhas e palavras. `head -n 3` e `tail -n 3` geram amostras do documento. A ordenação de capítulos usa `sort -zV` no parser.

### 03. Sistema de arquivos

`scripts/core/packager.sh` usa `tar --sort=name` para reunir os artefatos em ordem determinística e envia o fluxo a `gzip -n -9`. Datas, identidade e permissões são normalizadas sem alterar a publicação original. Outros módulos usam `mkdir`, `cp`, `mv`, `ln` e `rm` na preparação, publicação e limpeza de recursos temporários.

### 04. Permissões de arquivos

`chmod 755 "$DIST_DIR"`, em `catalyst.sh`, demonstra a representação octal. `chmod u=rw,go=r "$output_archive"`, no packager, demonstra a forma simbólica. O estado do servidor recebe `umask 077` e diretório privado. Em montagens Windows, a aplicação efetiva das permissões depende da configuração do filesystem.

### 05. Controle de processos

`scripts/core/server.sh` usa `ps -p "$pid"` para verificar se o processo registrado existe. A identidade também é conferida em `/proc/$pid/cmdline`, antes de considerar o PID como pertencente ao projeto.

### 06. Sinais

No servidor, `kill -15 -- "-$pid"` solicita o término do grupo de processos do preview. Depois da espera limitada, `kill -9` é o recurso de encerramento forçado. `trap` trata sinais e limpeza nos módulos de servidor e transação.

### 07. Redirecionamentos

O bloco de métricas em `catalyst.sh` termina com `> "$METRICS_FILE"`. `wc -l < "$OUTPUT_DOC"` lê diretamente o arquivo. Diagnósticos usam `>&2`, e operações silenciosas podem redirecionar erros para `/dev/null`.

### 08. Pipes e substituição de processo

`scripts/core/parser.sh` alimenta o laço de capítulos com `done < <(find ... -print0 | sort -zV)`. O pipe conecta descoberta e ordenação, a substituição de processo entrega o fluxo ao laço sem perder o contador em uma subshell do pipe.

### 09. Expansões do Shell

`TOTAL_DOCS=$((TOTAL_DOCS + 1))` demonstra expansão aritmética no parser. `$(...)` captura saídas de comandos, como os caminhos resolvidos e as contagens. Os arquivos enviados ao cloc usam expansão de caminhos e de chaves.

### 10. Variáveis

Em `catalyst.sh`, `PUBLISHED_DIR`, `DIST_DIR` e `OUTPUT_DOC` separam a publicação visível da área de trabalho. `configure_output_paths` recalcula os caminhos quando a transação seleciona staging.

### 11. Parâmetros posicionais e especiais

A CLI interpreta `$1`, `$#` e `"${@:2}"`. O servidor captura o PID do processo lançado em background com `local server_pid=$!`. Códigos de retorno, como `$?`, são usados no tratamento de falhas e na limpeza transacional.

### 12. Atributos de variáveis e funções

`readonly APP_NAME` protege uma constante, `export CATALYST_ENV` disponibiliza uma variável aos filhos, `declare -i TOTAL_DOCS=0` declara um inteiro. Arrays armazenam capítulos e artefatos. Funções como `build_snapshot` e `package_release` delimitam responsabilidades.

### 13. Expansões avançadas de parâmetros

`COMMAND="${COMMAND:-help}"`, em `scripts/core/cli-options.sh`, fornece a operação padrão após interpretar as opções. No servidor, `${target%%\?*}` remove a query da URL e `${target#/}` retira a barra inicial. No parser, `${doc#"$base_dir/"}` obtém o caminho relativo.

### 14. Testes condicionais

`if [ -f "$doc" ]; then`, no parser, verifica arquivos regulares. O servidor usa testes de diretório, leitura e existência, além de `[[ ... =~ ... ]]` para validar porta e codificação hexadecimal.

### 15. Seleção com case

`case "$COMMAND" in`, em `catalyst.sh`, seleciona a operação. Outro `case` trata opções de `serve`, no servidor, padrões de extensão definem o tipo de conteúdo HTTP.

### 16. Operadores lógicos

`[ $TOTAL_DOCS -gt 0 ] && ...`, no parser, condiciona a mensagem de contagem. `mkdir ... || { ...; exit 1; }`, na preparação, interrompe a execução quando não consegue criar a saída.

### 17. Repetição

`while IFS= read -r -d '' doc; do`, no parser, percorre nomes delimitados por NUL. `for` percorre artefatos e gerações, e `while` processa argumentos e monitora alterações. Os laços leem fontes explícitos, sem solicitar dados do teclado.

### 18. Expressões regulares

`scripts/core/validator.sh` usa `grep -E '^ERROR[[:space:]]'` no manifesto do compilador. A expressão combina início de linha e classe POSIX para identificar diagnósticos. O AWK usa regex para reconhecer títulos, cercas e referências, a resolução de caminhos é complementada pela conferência canônica em Shell.

### 19. Programa em sed

`scripts/core/sanitizer.sh` aplica o programa:

```bash
sed -e 's/\r$//' "$input_file" > "$output_file"
```

A transformação retira o CR da terminação de linha. Não elimina espaços significativos nem altera a indentação de exemplos. A escrita em outro arquivo preserva os fontes.

### 20. Programa em AWK

`scripts/core/markdown.awk` indexa títulos, diferencia texto de código, atribui IDs únicos e resolve referências por capítulo. Arrays associativos controlam IDs ocupados e destinos. `scripts/core/toc.awk` mantém contadores hierárquicos e gera sumário e JSON a partir do índice compartilhado.

## Evidência reproduzível

```bash
./catalyst.sh all
./catalyst.sh report
cloc catalyst.sh scripts/core/*.{sh,awk,py} scripts/academic-report.sh
```

A primeira operação atualiza a publicação com os fontes atuais, a segunda gera a evidência acadêmica. Não copie números de linha antigos para a planilha. Gere novamente depois de qualquer mudança nos fontes citados.
