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
2. **Sumário Hierárquico Indexado (TOC)**: Motor em **AWK** que identifica cabeçalhos (`#`, `##`, `###`), ignora blocos de código, atribui numeração sequencial (`1.`, `1.1.`, `1.1.1.`) e gera âncoras navegáveis compatíveis com GitHub e HTML.
3. **Higienização Léxica**: Remoção de espaços em branco residuais e normalização de cabeçalhos via **sed**.
4. **Auditoria de Links e Ativos**: Auditoria com Expressões Regulares (`grep -E -o`) para verificar a integridade de links internos e referências de imagens.
5. **Métricas e Telemetria**: Contagem de palavras e linhas com `wc`, extração de amostras com `head`/`tail`, e geração de hashes imutáveis `md5sum`.
6. **Empacotamento de Release**: Geração automatizada de tarball compactado (`.tar.gz`) com permissões rigorosas de acesso (`chmod 755` e `chmod u=rw,go=r`).
7. **Servidor HTTP com Controle de Sinais**: Servidor web em segundo plano com suporte a portas customizadas, monitorado por `ps` e encerrado graciosamente por sinal `kill -15` (com fallback para `kill -9`).
8. **Relatório Oficial SIGAA**: Subcomando dedicado `report` que numera o script com `nl -ba` e unifica a documentação para entrega acadêmica.
9. **Suíte de Testes Automatizados**: Subcomando `test` com 15 asserções automatizadas cobrindo todo o ciclo do sistema.
10. **Modo Observador Contínuo**: Subcomando `watch` com recompilação instantânea a cada arquivo salvo.
11. **Interface Web com Busca e Temas**: Painel web com busca instantânea, alternador de tema claro/escuro e folha de estilo para exportação em PDF via `@media print`.

---

## 📂 Estrutura do Repositório

```text
CatalystShellEngine/
├── catalyst.sh               # CLI mestre / orquestrador principal (executável)
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
├── dist/                     # Artefatos gerados pelo pipeline
│   ├── full-document.md      # Documento mestre consolidado e higienizado
│   ├── summary.md            # Sumário navegável gerado pelo AWK
│   ├── metrics.txt           # Relatório estatístico de linhas e palavras
│   ├── index.html            # Interface web interativa local
│   ├── sigaa-report.md       # Relatório unificado com código numerado para o SIGAA
│   ├── catalyst-release-*.tar.gz     # Pacote release pronto para distribuição
│   └── catalyst-release-*.tar.gz.md5 # Assinatura criptográfica MD5
├── README.md                 # Este documento de referência
└── CEFET_REPORT.md           # Documento oficial com a descrição do trabalho e planilha de 20 conceitos
```

---

## 🛠️ Guia de Uso da Linha de Comando (CLI)

O orquestrador `catalyst.sh` é 100% não-interativo (sem comando `read`):

```bash
# Conceder permissão de execução
chmod +x catalyst.sh

# Ativar autocompletar no Bash (Tab)
source scripts/completion.bash

# Executar o pipeline completo (build + validação + sumário + métricas + preview + release)
./catalyst.sh all

# Subcomandos específicos:
./catalyst.sh test        # Executa a suíte com 15 testes automatizados
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
- **Linhas de Código (`cloc`)**: **828 linhas de código Bourne Shell** (requisito mínimo: 30 linhas).
- **Entrada Não-Interativa**: 100% parametrizada via argumentos CLI (`$1`, `$@`), sem bloqueio de teclado.

Consulte o arquivo [`CEFET_REPORT.md`](CEFET_REPORT.md) para visualizar a **Planilha Oficial da Etapa 02** com as linhas exatas de código e justificativas técnicas.
