# ⚛️ Catalyst Shell Engine

> **Motor de Orquestração, Validação e Publicação de Documentação Técnica em Shell Script Puro (Bash)**  
> Projeto desenvolvido para a disciplina **TEFC: Shell Scripting - Engenharia da Computação (CEFET-MG)**.  
> **Projeto de Referência**: [GlassHub Catalyst](https://github.com/matheustheus27/GlassHubCatalyst).

[![GlassHub Bash](https://glasshub-quasar.vercel.app/api/badge?label=Bash&value=5.0%2B&icon=shell&url=https%3A%2F%2Freact.dev&shape=rounded&style=glass&glow=true&theme=glass-dark)](https://www.w3schools.com/bash/)
[![GlassHub CEFET-MG](https://glasshub-quasar.vercel.app/api/badge?label=Instituição&value=CEFET-MG&icon=sparkles&url=https%3A%2F%2Freact.dev&shape=rounded&style=glass&glow=true&theme=glass-dark)](https://www.cefetmg.br)
[![GlassHub Ecossistema](https://glasshub-quasar.vercel.app/api/badge?label=Ecossistema&value=GlassHub&icon=glasshub&url=https%3A%2F%2Freact.dev&shape=rounded&style=glass&glow=true&theme=glass-dark)](https://matheustheus27.github.io/)
[![GlassHub Conceitos](https://glasshub-quasar.vercel.app/api/badge?label=Conceitos&value=20%2F20&icon=star&url=https%3A%2F%2Freact.dev&shape=rounded&style=glass&glow=true&theme=glass-dark)](#03conformidadecomoenunciado20conceitos)
[![GlassHub Licença](https://glasshub-quasar.vercel.app/api/badge?label=Licença&value=Proprietária&icon=license&url=https%3A%2F%2Freact.dev&shape=rounded&style=glass&glow=true&theme=glass-dark)](https://raw.githubusercontent.com/matheustheus27/CatalystShellEngine/main/LICENSE)

---

## 📖 Visão Geral

O **Catalyst Shell Engine** resolve o problema real de fragmentação de documentação técnica em projetos de engenharia. Inspirado no ecossistema corporativo do **GlassHub Catalyst**, ele reimplementa todo o pipeline de compilação, parsing hierárquico e certificação documental de forma nativa e enxuta em **Shell Script puro**, utilizando exclusivamente os utilitários canônicos do ecossistema Unix/Linux (`awk`, `sed`, `grep`, `tar`, `gzip`, `ps`, `kill`, `chmod`, `nl`).

### 🚀 Funcionalidades Principais
1. **Consolidação Inteligente**: Agrupa capítulos Markdown em `docs/` em ordem natural (`sort -V`).
2. **Sumário Hierárquico Indexado (TOC)**: Motor em **AWK** que identifica cabeçalhos (`#`, `##`, `###`), ignora blocos de código, atribui numeração sequencial (`1.`, `1.1.`, `1.1.1.`) e gera IDs únicos para títulos repetidos, reconhece seis níveis e títulos Setext, e mantém o sumário consistente com a interface.
3. **Normalização segura**: Conversão de CRLF com **sed**, preservando indentação, cercas e quebras significativas do Markdown.
4. **Auditoria de Links e Ativos**: Auditoria com Expressões Regulares (`grep -E -o`) para verificar a integridade de links internos e referências de imagens.
5. **Métricas e Telemetria**: Contagem de palavras e linhas com `wc`, extração de amostras com `head`/`tail`, e geração de checksums SHA-256 e MD5 de compatibilidade.
6. **Empacotamento de Release**: Geração automatizada de tarball compactado (`.tar.gz`) com permissões rigorosas de acesso (`chmod 755` e `chmod u=rw,go=r`).
7. **Servidor HTTP com Controle de Sinais**: Servidor web em segundo plano com suporte a portas customizadas, monitorado por `ps` e encerrado graciosamente por sinal `kill -15` (com fallback para `kill -9`).
8. **Relatório Oficial SIGAA**: Subcomando dedicado `report` que numera o script com `nl -ba` e unifica a documentação para entrega acadêmica.
9. **Suíte de Testes Automatizados**: Subcomando `test` com testes de integração e regressão em ambiente temporário Linux cobrindo todo o ciclo do sistema.
10. **Modo Observador Contínuo**: Subcomando `watch` com recompilação instantânea a cada arquivo salvo.
11. **Interface Web com Busca e Temas**: Painel web com busca instantânea, alternador de tema claro/escuro e folha de estilo para exportação em PDF via `@media print`.

---

## 📂 Estrutura do Repositório

```text
CatalystShellEngine/
├── catalyst.sh               # CLI mestre / orquestrador principal (executável)
├── templates/index.html      # Interface HTML/CSS/JavaScript usada pelo preview
├── docs/                     # Capítulos completos de documentação técnica
│   ├── 00-cover.md           # Capa oficial e metadados institucionais
│   ├── 01-overview.md        # Visão geral, contexto do GlassHub e matriz de capacidades
│   ├── 02-architecture.md    # Filosofia Unix, estágios de compilação e diagramas Mermaid
│   ├── 03-concepts.md        # Detalhamento exaustivo dos 20 conceitos avaliados
│   ├── 04-usage-guide.md     # Manual completo de operação da linha de comando
│   ├── 05-benchmarks.md      # Análise de performance vs. GlassHub Catalyst original
│   └── 06-conclusion.md      # Considerações finais, maturidade e roadmap
├── images/                   # Ativos gráficos e logotipos
├── scripts/                  # Módulos especializados em Shell Script
│   ├── completion.bash       # Autocompletion para terminal Bash (Tab)
│   ├── core/
│   │   ├── parser.sh         # Consolidação e motor AWK
│   │   ├── validator.sh      # Auditoria Regex com grep -E
│   │   ├── sanitizer.sh      # Normalização com sed
│   │   ├── packager.sh       # Empacotamento tar.gz, md5sum e chmod
│   │   └── server.sh         # Controle de processos (ps, kill)
│   └── utils/
│       └── logger.sh         # Cores ANSI e formatação de saída
├── dist/                     # Artefatos organizados gerados pelo pipeline
│   ├── index.html            # Único arquivo na raiz: Interface web interativa + DocBot
│   ├── docs/                 # Documentos consolidados (full-document.md, summary.md)
│   ├── metrics/              # Telemetria quantitativa (metrics.txt)
│   ├── reports/              # Relatórios acadêmicos (sigaa-report.md)
│   └── releases/             # Pacotes de distribuição (tar.gz e .md5)
├── README.md                 # Este documento de referência
└── CEFET_REPORT.md           # Documento oficial com a descrição do trabalho e planilha reproduzível de 20 conceitos
```

---

## 🛠️ Guia de Uso da Linha de Comando (CLI)

O orquestrador `catalyst.sh` é não-interativo (sem leitura de entrada do teclado):

```bash
# Conceder permissão de execução
chmod +x catalyst.sh

# Ativar autocompletar no Bash (Tab)
source scripts/completion.bash

# Executar o pipeline completo (build + validação + sumário + métricas + preview + release)
./catalyst.sh all

# Subcomandos específicos:
./catalyst.sh test        # Executa testes de integração e regressão isolados
./catalyst.sh report      # Gera o relatório unificado com código numerado (nl -ba) para o SIGAA
./catalyst.sh watch       # Entra em modo observador com recompilação automática
./catalyst.sh build       # Consolida capítulos, higieniza com sed e gera o sumário com AWK
./catalyst.sh validate    # Audita links e imagens via Regex estendida
./catalyst.sh toc         # Extrai exclusivamente o sumário hierárquico via AWK
./catalyst.sh stats       # Exibe as métricas de publicação (linhas, palavras, amostras)
./catalyst.sh pack        # Cria o tarball de release em dist/ com md5sum
./catalyst.sh clean       # Limpa com segurança o diretório dist/
./catalyst.sh help        # Exibe a ajuda detalhada
```

### Servidor de Preview Local
```bash
# Iniciar na porta padrão (8000)
./catalyst.sh serve

# Iniciar em porta customizada (ex: 8080)
./catalyst.sh serve 8080
# ou
./catalyst.sh serve --port 8080

# Encerrar o servidor ativo via sinal kill
./catalyst.sh serve --stop
```

---

## 🎓 Conformidade com o enunciado

- **Disciplina**: TEFC: Shell Scripting - Engenharia da Computação.
- **Conceitos Contemplados**: **20 de 20 conceitos** (requisito mínimo: 15).
- **Linhas de Código (`cloc`)**: contagem atual gerada por `cloc catalyst.sh scripts/core/*.sh scripts/academic-report.sh` (requisito mínimo: 30 linhas).
- **Entrada Não-Interativa**: 100% parametrizada via argumentos CLI (`$1`, `$@`), sem bloqueio de teclado.

Consulte o arquivo [`CEFET_REPORT.md`](CEFET_REPORT.md) para visualizar a **Planilha Oficial da Etapa 02** com instruções para gerar a planilha com as linhas atuais e o PDF de entrega.


## Execução diretamente no Linux

No Ubuntu ou Debian, instale as dependências no terminal:

```bash
sudo apt update
sudo apt install -y git bash coreutils findutils grep sed gawk tar gzip util-linux netcat-openbsd curl cloc
```

Clone o projeto e entre no diretório (se já tiver uma cópia, entre nela):

```bash
git clone https://github.com/matheustheus27/CatalystShellEngine.git
cd CatalystShellEngine
chmod +x catalyst.sh
```

Execute o pipeline, os testes e o relatório acadêmico:

```bash
./catalyst.sh all
./catalyst.sh test
./catalyst.sh report
```

Os arquivos gerados ficam em `dist/`. Para visualizar a documentação no navegador:

```bash
./catalyst.sh serve --port 8080
# Abra http://127.0.0.1:8080 no navegador.
# Ao terminar:
./catalyst.sh serve --stop
```

Para exportar também o relatório em PDF, instale as dependências opcionais e use
um ambiente Python isolado:

```bash
sudo apt install -y python3 python3-venv fonts-dejavu-core
python3 -m venv .venv-report
.venv-report/bin/python -m pip install reportlab
CATALYST_PDF_PYTHON=.venv-report/bin/python ./catalyst.sh report --pdf
```

O PDF será salvo em `dist/reports/sigaa-report.pdf`. Em outras distribuições Linux,
instale os pacotes equivalentes usando o gerenciador da distribuição; o preview
exige a variante OpenBSD do netcat, com suporte a `nc -N`.

## Execução no Ubuntu WSL e entrega acadêmica

O núcleo exige Bash e ferramentas GNU/Linux. O preview utiliza OpenBSD netcat
(`nc -N`), `setsid`, `flock`, `realpath` e `timeout`; a suíte também usa `curl` e
`cloc`. No Ubuntu, instale `netcat-openbsd`, `util-linux`, `curl` e `cloc`, além
dos utilitários de texto e compressão descritos no manual.

```powershell
wsl -d Ubuntu --exec bash /mnt/p/Git/GitHub/CatalystShellEngine/catalyst.sh all
wsl -d Ubuntu --exec bash /mnt/p/Git/GitHub/CatalystShellEngine/catalyst.sh test
wsl -d Ubuntu --exec bash /mnt/p/Git/GitHub/CatalystShellEngine/catalyst.sh report
```

A suíte copia os fontes para `/tmp` e valida permissões em filesystem Linux.
Em unidades Windows montadas sem a opção `metadata`, `chmod` pode não produzir as
mesmas permissões observadas no Linux. O preview escuta em `127.0.0.1`, valida as
portas e mantém estado privado por projeto/usuário.

O comando `report --pdf` exporta a entrega com código numerado, planilha dinâmica e
saída real do `cloc`. A dependência opcional Python/ReportLab e a configuração de
`CATALYST_PDF_PYTHON` estão descritas em [CEFET_REPORT.md](CEFET_REPORT.md).

A CLI em `catalyst.sh` carrega os módulos de parser, sanitização, validação,
empacotamento, preview, transação e configuração de completion. O servidor é
executado como módulo externo. A interface HTML/CSS/JavaScript fica em
`templates/index.html`, `templates/app.css` e `templates/app.js`. Cada responsabilidade possui uma única implementação.

Melhorias futuras e limites estão no [capítulo de conclusão](docs/06-conclusion.md).


## Publicação transacional e CI

Cada comando que altera a saída adquire `flock` em `.catalyst/build.lock`, cria
um staging exclusivo no mesmo filesystem e publica somente após sucesso. Builds
inválidos ou interrompidos preservam a última saída válida. `validate` verifica
os fontes atuais em staging e não altera a publicação. `toc`, `sanitize` e `stats`
atualizam um snapshot completo para manter documento, sumário e interface coerentes.

Em filesystem Linux, `dist` é um link para uma geração em `.catalyst/`; o commit
substitui esse link por rename atômico, mantendo a geração anterior. A migração
inicial de um diretório `dist` legado usa o bloqueio de publicação.

Em unidades Windows montadas pelo WSL (DrvFS/v9fs), o modo automático mantém
`dist` como diretório legível pelo Windows. Nesse modo, arquivos são substituídos
sob `.catalyst/publish.lock`, com backup e journal para rollback e recuperação.
A CLI e o preview respeitam esse bloqueio; leitores externos que não o utilizam
podem observar arquivos de gerações diferentes durante o commit. Para exigir a
troca atômica do snapshot inteiro, execute em filesystem Linux nativo.

É possível selecionar explicitamente `CATALYST_PUBLISH_MODE=symlink` ou
`CATALYST_PUBLISH_MODE=directory` antes da primeira publicação. Não edite `dist`
manual ou simultaneamente; os fontes ficam em `docs`, `images` e `templates`.
Não remova `.catalyst` enquanto houver processos do projeto em execução.

O workflow `.github/workflows/ci.yml` executa em pushes e pull requests, no Ubuntu
22.04 e 24.04, com permissões de leitura. Ele verifica sintaxe, ShellCheck, testes
de integração, HTTP, concorrência, interrupções e rollback, e guarda os artefatos.
Para executar as mesmas verificações localmente:

```bash
sudo apt install -y shellcheck python3
# Para os testes da interface: Node.js 24.22.2 (somente desenvolvimento).
npm ci --ignore-scripts --no-audit --no-fund
bash scripts/ci/check.sh
```


## Markdown, interface offline e preview concorrente

O compilador GNU AWK faz uma passagem de índice antes da reescrita. Ele reconhece
títulos ATX de H1 a H6 e Setext, gera IDs ASCII com sufixos para repetições, respeita
o tipo e comprimento das cercas de código e expande links de referência por capítulo.
Capítulos podem estar em subdiretórios de `docs/`; caminhos relativos e fragmentos
são resolvidos a partir do arquivo de origem. Ativos referenciados são copiados para
`dist/assets/files/` e links entre capítulos apontam para os IDs do livro consolidado.
Exemplos em código não são tratados como links. O parser cobre esse subconjunto;
não é uma implementação completa de CommonMark.

A interface usa bundles locais de Marked, DOMPurify e Mermaid, com versões e
integridade registradas em `vendor/manifest.json` e `vendor/SHA256SUMS`. O build
verifica os checksums e não baixa dependências. HTML e respostas do DocBot passam
por sanitização; IDs de navegação são atribuídos a partir do índice do compilador.
A CSP bloqueia scripts inline, frames e conexões externas. Estilos inline são
permitidos para os SVGs do Mermaid; estilos arbitrários dos documentos são removidos.
Imagens remotas são substituídas pelo texto alternativo para manter o uso offline.
Os previews aplicam uma CSP sandbox separada aos ativos publicados. Se usar outro
servidor, configure cabeçalhos equivalentes; a CSP do index não protege arquivos
HTML/SVG abertos como documentos separados.

Para atualizar os bundles, revise as versões em `scripts/vendor/update.py` e execute
esse script explicitamente com acesso à internet. Inclua os bundles, licenças,
manifesto e checksums atualizados no mesmo commit. Node/npm são necessários apenas
para os testes da interface, não para executar o pipeline.

O servidor Bash continua sendo o padrão. Para múltiplas conexões simultâneas:

```bash
./catalyst.sh all
./catalyst.sh serve --backend threaded --port 8080
# Abra http://127.0.0.1:8080
./catalyst.sh serve --restart   # Preserva backend e porta.
./catalyst.sh serve --stop
```

O backend `threaded` utiliza somente a biblioteca padrão do Python 3.10+, limita
conexões ativas a 32 e aplica timeout aos clientes. Ambos os backends escutam em
`127.0.0.1`, compartilham o controle de PID, respeitam o lock de publicação e
acompanham novos builds sem reiniciar. São previews locais, não servidores de produção.
