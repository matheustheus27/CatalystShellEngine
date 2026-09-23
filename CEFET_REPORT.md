# Relatório do Projeto: Catalyst Shell Engine

**Instituição**: Centro Federal de Educação Tecnológica de Minas Gerais (CEFET-MG)  
**Departamento**: Departamento de Computação (DECOM)  
**Disciplina**: TEFC: Shell Scripting - Engenharia da Computação  
**Aluno**: Matheus Thiago de Souza Ferreira  
**Ano/Semestre**: 2026/2  
**Projeto de Referência**: [GlassHub Catalyst](https://github.com/matheustheus27/GlassHubCatalyst)  
**Script Principal Avaliado**: [`catalyst.sh`](catalyst.sh)  

---

## Etapa 01: Definição do Problema (Envio para a Lista de Discussão)

> **Destinatário**: `decom042@googlegroups.com`  
> **Prazo Oficial**: 29/09/2026  
> **Assunto**: `[TEFC Shell Scripting] Proposta de Projeto - Catalyst Shell Engine`

### Proposta de Texto Formatada para Envio:

```text
Prezado Professor e Colegas,

Gostaria de submeter a proposta de projeto para a disciplina TEFC: Shell Scripting.

Título do Projeto: Catalyst Shell Engine - Motor Automatizado de Consolidação, Validação Léxica e Publicação de Documentação Técnica

Contexto e Referência:
Inspirado na arquitetura corporativa do GlassHub Catalyst (ferramenta de governança e documentação viva da GlassHub), este projeto reimplementa todo o núcleo de compilação, parsing e auditoria documental utilizando 100% de recursos nativos do ecossistema Unix/Linux em Shell Script (Bash).

Descrição do Problema:
Em projetos corporativos de engenharia de software, a documentação técnica de arquitetura é rotineiramente fragmentada em múltiplos arquivos Markdown distribuídos em diretórios. Essa fragmentação dificulta a leitura linear, quebra referências e links relativos, dispersa sumários e demanda ferramentas pesadas (Node.js, Docker, Python) para simples tarefas de inspeção e compilação em servidores ou pipelines CI/CD.

Solução Proposta em Shell Script:
O Catalyst Shell Engine é uma ferramenta de linha de comando desenvolvida 100% em Shell Script (Bash) que automatiza a governança documental:
1. Fonte Externa Consumida: Coleta e consome arquivos Markdown estruturados no diretório docs/ em ordem natural (sort -V).
2. Extração Hierárquica de Sumário: Processa cabeçalhos através de um programa em AWK com acumuladores e âncoras slug, gerando um sumário indexado e numerado automaticamente (1., 1.1., etc.), ignorando blocos de código.
3. Higienização Léxica: Utiliza programas em sed para remoção de espaços em branco redundantes em final de linha e padronização da sintaxe de títulos.
4. Auditoria de Links e Imagens: Emprega grep com Expressões Regulares estendidas (-E -o) para validar links internos, imagens e âncoras locais.
5. Produção Externa de Informação: Gera o documento mestre consolidado (full-document.md), sumário (summary.md), relatório de métricas estatísticas (linhas e palavras via wc), interface web interativa com busca, temas e impressão PDF (index.html) e empacota o release compactado (.tar.gz com permissões de acesso via chmod e hashes de integridade via md5sum).
6. Servidor de Pré-visualização: Controla um servidor HTTP local em background com suporte a portas customizadas, gerenciando seu ciclo de vida através de inspeção de processos (ps) e envio de sinais de término (kill -15 / kill -9).
7. Automação Avançada: Inclui gerador de relatório SIGAA com código numerado por nl -ba (report), modo de observação com recompilação contínua (watch), suíte de testes automatizados com asserções (test), scripts de autocompletion e tratamento de sinais com trap.

O projeto é operado exclusivamente através de flags e parâmetros de linha de comando ($1, $@), sem qualquer leitura interativa via teclado (read), em estrita conformidade com os requisitos da disciplina.

Atenciosamente,
Matheus Ferreira
Engenharia da Computação - CEFET-MG
```

---

## Etapa 02: Planilha de Conceitos Utilizados (Submissão SIGAA)

A tabela a seguir apresenta os conceitos utilizados no script principal [`catalyst.sh`](catalyst.sh), cobrindo **integralmente os 20 conceitos** previstos no enunciado (superando o requisito mínimo de 15 conceitos). O formato de colunas atende estritamente à especificação da Seção 2 e Seção 3 do enunciado:

| # | Conceito | Aula | Linha | Trecho de Código | Descrição |
|---|---|---|---|---|---|
| 01 | 01 Comandos básicos | Comandos básicos | 60 | `echo " Data do Sistema: $(date '+%d/%m/%Y %H:%M:%S')"` | Exibição de cabeçalho formatado utilizando os comandos `echo` e `date`. |
| 02 | 02 Processamento de texto | Processamento de texto | 267 | `TOTAL_LINES=$(wc -l < "$OUTPUT_DOC")` | Contagem total de linhas do documento unificado utilizando o utilitário `wc -l`. |
| 03 | 03 Sistema de arquivos | Sistema de arquivos | 1691 | `tar -czf "$OUTPUT_BUNDLE" -C "$DIST_DIR" ...` | Empacotamento e compressão de múltiplos arquivos em formato tarball gzip via `tar -czf`. |
| 04 | 04 Permissões | Sistema de arquivos | 105 | `chmod 755 "$DIST_DIR"` | Configuração de permissões de diretório em representação octal estrita (`755`). |
| 05 | 05 Processos | Processos | 1740 | `if ps -p "$active_pid" >/dev/null 2>&1; then` | Inspeciona a tabela de processos do sistema com `ps -p` para checar se o servidor está ativo. |
| 06 | 06 Sinais | Processos | 1743 | `kill -15 "$active_pid" 2>/dev/null || kill -9 ...` | Envio de sinal `SIGTERM` (-15) e fallback `SIGKILL` (-9) para encerramento de processo. |
| 07 | 07 Redirecionamentos | Entradas, saídas e Redirecionamentos | 108 | `> "$METRICS_FILE"` | Truncamento e inicialização limpa de arquivo de métricas utilizando redirecionamento `>`. |
| 08 | 08 Pipes ou redirecionamentos avançados | Entradas, saídas e Redirecionamentos | 122 | `ls "$DOCS_DIR"/*.md 2>/dev/null | sort -V` | Redirecionamento de erro `2>/dev/null` e pipe `|` para ordenação natural com `sort -V`. |
| 09 | 09 Expansões | Expansões | 130 | `TOTAL_DOCS=$((TOTAL_DOCS + 1))` | Incremento de contador numérico utilizando expansão aritmética `$(( ... ))`. |
| 10 | 10 Variáveis | Parâmetros e Variáveis | 25 | `DIST_DIR="${BASE_DIR}/dist"` | Definição de variável de ambiente de usuário para armazenar o caminho de saída. |
| 11 | 11 Parâmetros posicionais e especiais | Parâmetros e Variáveis | 1780 | `local server_pid=$!` | Uso do parâmetro especial `$!` para capturar o PID do processo disparado em background. |
| 12 | 12 Atributos de variáveis | Parâmetros e Variáveis | 17 | `readonly APP_NAME="Catalyst Shell Engine"` | Definição de variável com atributo de somente-leitura (`readonly`). |
| 13 | 13 Expansões avançadas | Parâmetros e Variáveis | 1954 | `COMMAND="${1:-help}"` | Uso de expansão avançada com fallback de valor padrão `${1:-help}`. |
| 14 | 14 Testes condicionais com test ou if | Estruturas de fluxo condicionais | 124 | `if [ -f "$doc" ]; then` | Teste condicional verificando existência e tipo de arquivo regular com `-f`. |
| 15 | 15 Testes condicionais com case | Estruturas de fluxo condicionais | 1957 | `case "$COMMAND" in build) ... ;; esac` | Estrutura de seleção múltipla `case` para roteamento de subcomandos da CLI. |
| 16 | 16 Outras formas de desvio | Estruturas de fluxo condicionais | 141 | `[ $TOTAL_DOCS -gt 0 ] && echo "Total de capitulos: $TOTAL_DOCS"` | Desvio condicional inline através do operador lógico `&&`. |
| 17 | 17 Comandos ou sequenciadores | Estruturas de fluxo de repetição | 122 | `for doc in $(ls "$DOCS_DIR"/*.md 2>/dev/null | sort -V); do` | Estrutura de repetição `for` para iteração ordenada sobre a lista de arquivos Markdown. |
| 18 | 18 Expressão regular básica ou estendida | Expressões Regulares | 248 | `grep -E -o "$link_pattern" "$OUTPUT_DOC"` | Busca por links com `grep -E -o` utilizando regex estendida com metacaracteres `\[[^]]+\]\(([^)]+)\)`. |
| 19 | 19 Programa em sed | sed | 144 | `sed -E -e 's/[ \t]+$//' -e 's/^(#+)[ \t]+/\1 /'` | Script em `sed` para higienização de espaços no final de linha e normalização de hashtags. |
| 20 | 20 Programa em AWK | AWK | 173 | `awk 'BEGIN { h1=0; in_code=0; } /^# [^#]/ { ... }'` | Script em `AWK` para leitura de cabeçalhos Markdown e geração de sumário hierárquico indexado. |

---

## Verificação de Linhas de Código via CLOC

O enunciado exige expressamente:
> *"O shell script deverá ter no mínimo 30 (trinta) linhas de código verificadas pela ferramenta cloc (https://github.com/AlDanial/cloc)."*

Execução oficial da ferramenta `cloc v2.11` sobre o arquivo [`catalyst.sh`](catalyst.sh):

```bash
cloc catalyst.sh
```

### Resultado Oficial da Auditoria:
```text
        1 text file.
        1 unique file.
        0 files ignored.

github.com/AlDanial/cloc v 2.11  T=0.02 s (51.4 files/s, 61992.4 lines/s)
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
Bourne Shell                     1            108            113           1187
-------------------------------------------------------------------------------
```

- **Linhas Efetivas de Código (code)**: **1187 linhas** (superando em **39,5x** a exigência de 30 linhas).
- **Linhas de Comentários (comment)**: **113 linhas**.
- **Linhas em Branco (blank)**: **108 linhas**.
- **Total de Linhas do Arquivo**: **1408 linhas**.

---

## Instruções para a Apresentação Oral (Etapa 03)

- **Tempo Máximo**: 20 minutos.
- **Roteiro Recomendado**:
  1. Apresentação do problema real de documentação técnica fragmentada e a motivação do GlassHub Catalyst (3 min).
  2. Demonstração prática da execução ao vivo (`./catalyst.sh all`, `./catalyst.sh validate`, `./catalyst.sh stats`, `./catalyst.sh test`) (7 min).
  3. Demonstração do servidor web em background (`./catalyst.sh serve 8080`), busca instantânea, temas e encerramento com `kill` (`./catalyst.sh serve --stop`) (4 min).
  4. Apresentação da geração automática do relatório com código numerado para o SIGAA (`./catalyst.sh report`) (2 min).
  5. Apresentação da planilha com os 20 conceitos e os programas em AWK e sed no código-fonte (3 min).
  6. Espaço para perguntas e encerramento (1 min).
