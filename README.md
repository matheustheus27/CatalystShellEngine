# ⚛️ Catalyst Shell Engine

> **Aplicação Shell que cataloga, valida e gera documentação web técnica a partir de arquivos Markdown.**
>
> Projeto desenvolvido para a disciplina **TEFC: Shell Scripting - Engenharia da Computação (CEFET-MG)**.
>
> **Projeto de Referência**: [GlassHub Catalyst](https://github.com/matheustheus27/GlassHubCatalyst).

[![GlassHub Bash](https://glasshub-quasar.vercel.app/api/badge?label=Bash&value=5.0%2B&icon=shell&url=https%3A%2F%2Freact.dev&shape=rounded&style=glass&glow=true&theme=glass-dark)](https://www.w3schools.com/bash/)
[![GlassHub CEFET-MG](https://glasshub-quasar.vercel.app/api/badge?label=Instituição&value=CEFET-MG&icon=sparkles&url=https%3A%2F%2Freact.dev&shape=rounded&style=glass&glow=true&theme=glass-dark)](https://www.cefetmg.br)
[![GlassHub Ecossistema](https://glasshub-quasar.vercel.app/api/badge?label=Ecossistema&value=GlassHub&icon=glasshub&url=https%3A%2F%2Freact.dev&shape=rounded&style=glass&glow=true&theme=glass-dark)](https://matheustheus27.github.io/)
[![GlassHub Conceitos](https://glasshub-quasar.vercel.app/api/badge?label=Conceitos&value=20%2F20&icon=star&url=https%3A%2F%2Freact.dev&shape=rounded&style=glass&glow=true&theme=glass-dark)](docs/03-concepts.md)
[![GlassHub Licença](https://glasshub-quasar.vercel.app/api/badge?label=Licença&value=Proprietária&icon=license&url=https%3A%2F%2Freact.dev&shape=rounded&style=glass&glow=true&theme=glass-dark)](https://raw.githubusercontent.com/matheustheus27/CatalystShellEngine/main/LICENSE)

---

## 📖 Visão Geral

**Autor**: Matheus Thiago de Souza Ferreira. **Período acadêmico**: 2026/2.

O programa recebe capítulos fragmentados em `docs/`, ordena os arquivos, normaliza o texto, gera um sumário hierárquico numerado com GNU AWK, valida referências locais e empacota a documentação para publicação. A [proposta apresentada ao professor](docs/01-overview.md#proposta-apresentada) orienta o escopo deste repositório.

### 🚀 Funcionalidades Principais

1. **Consolidação de Capítulos**: Descoberta recursiva em `docs/` e ordenação natural com `sort -zV`.
2. **Sumário Hierárquico Numerado**: GNU AWK reconhece H1-H6/Setext e gera IDs únicos para navegação.
3. **Normalização de Texto**: sed converte CRLF sem remover espaços significativos ou alterar os fontes.
4. **Validação de Referências Locais**: Regex, índice por capítulo e caminhos canônicos verificam links, fragmentos e ativos, a auditoria Markdown informa arquivo, linha, destino e motivo.
5. **Métricas de Publicação**: `wc`, `head` e `tail` produzem contagens e amostras.
6. **Empacotamento de Release**: `.tar.gz` com permissões explícitas, SHA-256 e checksum de compatibilidade.
7. **Preview com Controle de Processos**: Backend Bash/netcat e modo concorrente Python opcional, com porta, PID e sinais.
8. **Relatório Acadêmico**: Planilha dinâmica de conceitos, execução real do cloc e código numerado por `nl -ba`.
9. **Testes Automatizados**: Integração, regressões, transações, HTTP e testes da interface offline.
10. **Observação de Alterações**: `watch` verifica checksums de Markdown a cada segundo e recompila, sem recarga automática da aba.
11. **Interface Web Interativa**: Busca, temas, modo foco, Mermaid e assistente local com bibliotecas vendorizadas.

---

## 🛠️ Comece por aqui

Em Ubuntu ou Debian, instale as dependências. Este conjunto inclui demonstração, testes e relatório em Markdown:

```bash
sudo apt update
sudo apt install -y git bash coreutils findutils grep sed gawk tar gzip util-linux netcat-openbsd curl cloc python3
git clone https://github.com/matheustheus27/CatalystShellEngine.git
cd CatalystShellEngine
chmod +x catalyst.sh
./catalyst.sh all
./catalyst.sh serve
```

Se já possui uma cópia, entre nela e execute os dois últimos comandos. Abra **http://127.0.0.1:8000**. Use HTTP: abrir `dist/index.html` por `file://` impede o carregamento normal dos documentos pela interface.

```bash
./catalyst.sh serve --restart   # Reinicia o servidor, mantém porta e backend.
./catalyst.sh serve --stop      # Encerra o preview.
```

O [manual de uso](docs/04-usage-guide.md) reúne instalação no Linux, execução no WSL, comandos, exemplos e solução de problemas.

---

## 🗂️ Outros Projetos, Auditoria e Demonstração

As opções `--docs` e `--output` selecionam capítulos e publicação, com caminhos relativos ao diretório atual ou absolutos. A pasta pai de `--docs` é a raiz dos ativos. Sem opções, permanecem `docs/` e `dist/` do motor.

```bash
./catalyst.sh all --docs examples/demo/docs --output /tmp/catalyst-demo-site
./catalyst.sh serve --output /tmp/catalyst-demo-site --port 8081
./catalyst.sh serve --output /tmp/catalyst-demo-site --stop
./catalyst.sh demo
```

O relatório da última tentativa fica ao lado da saída: `/tmp/catalyst-demo-site.validation.md`, ou `dist.validation.md` no caso padrão. Ele registra referências, arquivos, linhas e motivos de falha. Uma publicação válida também inclui `reports/validation.md`. A auditoria mais recente pode reprovar enquanto a última publicação válida continua intacta.

O [exemplo de demonstração](examples/demo/README.md) reúne títulos repetidos, subpastas, imagem, arquivo com espaços e referências inválidas fora da entrada normal. `demo` executa o roteiro em uma cópia temporária e verifica a preservação da publicação. As saídas têm locks e estado próprios, não selecione como destino uma pasta com arquivos alheios ao Catalyst.

---

## ⚙️ O que pertence ao projeto em Shell

O núcleo de geração executa em **Bash e utilitários GNU/Linux**, com programas em **AWK e sed**. O comando `all` não precisa de Node, Python ou acesso à internet, desde que os utilitários e os bundles já estejam presentes.

- **Entrada:** arquivos `docs/**/*.md`, referências locais e ativos do projeto.
- **Processamento:** catálogo em ordem natural, normalização CRLF, índice de títulos, sumário numerado, validação com regex e caminhos canônicos, métricas e empacotamento.
- **Saída:** Markdown consolidado, metadados, HTML, ativos locais, métricas e `.tar.gz` com SHA-256.
- **Operação:** argumentos de linha de comando, nenhum pedido de dados pelo teclado. Os usos de `read` consomem arquivos, pipes ou requisições HTTP.

A interface gerada usa HTML, CSS e JavaScript, com Marked, DOMPurify e Mermaid distribuídos localmente. O preview padrão usa Bash e OpenBSD netcat. Python é usado no backend concorrente opcional, nos testes e no exportador PDF, Node/npm são ferramentas de desenvolvimento para os testes da interface. Essas partes complementam o pipeline acadêmico em Shell.

---

## 🚀 Fluxo de Trabalho

1. Edite os capítulos em `docs/`. Use prefixos como `01-`, `02-` e `10-` para orientar a ordem natural, subpastas também são percorridas.
2. Execute `./catalyst.sh validate` para verificar os fontes sem alterar a publicação.
3. Execute `./catalyst.sh all` para compilar, validar e gerar o pacote.
4. Consulte a documentação com `./catalyst.sh serve` ou atualize o navegador se o servidor já estiver ativo.
5. Gere a entrega acadêmica separadamente com `./catalyst.sh report --pdf`, após preparar o exportador.

`build`, `toc`, `sanitize` e `stats` reconstroem um snapshot consistente. `pack` e `report` aproveitam o snapshot existente quando completo, execute `all` depois de editar os fontes e antes da entrega final. `all` não gera o relatório acadêmico por conta própria.

---

## 📂 Organização e Saídas

```text
CatalystShellEngine/
├── catalyst.sh               # CLI e orquestração
├── docs/                     # Capítulos processados pelo próprio projeto
├── scripts/
│   ├── core/                 # Parser, AWK, sed, validação, transação e servidores
│   ├── tests/                # Integração, regressões, HTTP e interface
│   ├── ci/check.sh           # Verificações locais e do GitHub Actions
│   ├── academic-report.sh    # Evidências e código numerado
│   └── export-report-pdf.py  # Exportador opcional
├── templates/                # index.html, app.css, app.js e csp.txt
├── vendor/                   # Bibliotecas da interface, licenças e checksums
├── images/                   # Ativos do projeto
├── .catalyst/                # Staging, locks e gerações, não editar manualmente
└── dist/                     # Saída gerada
    ├── index.html
    ├── docs/                 # full-document.md, summary.md e índices JSON/TSV
    ├── ui/                   # CSS, JavaScript e bibliotecas locais
    ├── assets/               # Imagens e arquivos locais referenciados
    ├── metrics/metrics.txt
    ├── reports/              # sigaa-report.md e, quando exportado, PDF
    └── releases/             # tar.gz, .sha256 e checksum de compatibilidade
```

No Linux, a publicação troca atomicamente um link para a geração concluída. Em unidades Windows montadas pelo WSL, mantém um diretório com journal, rollback e bloqueio para leitores cooperantes. Os detalhes estão na [arquitetura](docs/02-architecture.md).

---

## 🎓 Conformidade com o Enunciado

- **Entrada e saída por arquivos**: capítulos Markdown e ativos geram uma publicação organizada em `dist/`.
- **Operação não interativa**: argumentos da CLI, sem solicitação de dados pelo teclado.
- **Conceitos documentados**: vinte aplicações com evidências resolvidas nos fontes atuais, o mínimo solicitado é quinze.
- **Contagem de código**: execução real do cloc no relatório, com a categoria Shell identificada para conferir o mínimo de trinta linhas.
- **Entrega acadêmica**: código numerado, planilha com seis colunas e PDF gerado separadamente por `report --pdf`.

Consulte o [guia acadêmico](CEFET_REPORT.md) para geração, revisão e apresentação.

---

## 📚 Documentação por Assunto

- [Visão geral e proposta](docs/01-overview.md): problema, escopo e cinco objetivos apresentados.
- [Arquitetura](docs/02-architecture.md): módulos, etapas, arquivos e publicação transacional.
- [Conceitos da disciplina](docs/03-concepts.md): vinte evidências de aplicação em Shell.
- [Manual operacional](docs/04-usage-guide.md): dependências, Linux/WSL, Markdown, CLI e diagnóstico.
- [Testes e medições](docs/05-benchmarks.md): comportamento, integridade e desempenho.
- [Resultados e limites](docs/06-conclusion.md): capacidades atuais e melhorias futuras.
- [Entrega acadêmica](CEFET_REPORT.md): requisitos, geração do PDF e apresentação.

---

## 🧪 Verificação e Manutenção

```bash
./catalyst.sh test
```

A suíte usa diretórios temporários Linux e verifica pipeline, validação, transações, recuperação, permissões e previews. Para as verificações completas, instale também ShellCheck e Node.js **24.22.2**, depois execute:

```bash
npm ci --ignore-scripts --no-audit --no-fund
bash scripts/ci/check.sh
```

O workflow `.github/workflows/ci.yml` executa essas verificações em Ubuntu 22.04 e 24.04, em pushes e pull requests. Não é necessário executar npm para publicar a documentação.

O build verifica `vendor/SHA256SUMS` e não baixa bibliotecas. Atualizações são explícitas, por `scripts/vendor/update.py`, conforme o manual. O parser cobre um subconjunto de Markdown, e os previews são locais. Consulte os limites antes de adaptar o projeto a outro ambiente.

---

## 📜 Licença e Identidade do Projeto

Os termos do projeto estão em `LICENSE`. As dependências vendorizadas mantêm suas próprias licenças em `vendor/`.
