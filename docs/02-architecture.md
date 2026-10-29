# 02. Arquitetura e Engenharia de Pipeline

## Princípios de Design e Filosofia Unix

O design arquitetural do **Catalyst Shell Engine** fundamenta-se nos princípios canônicos da filosofia Unix formulados por Doug McIlroy e Brian Kernighan:

1. **Faça apenas uma coisa e faça-a bem**: Cada subcomando do motor (`build`, `validate`, `toc`, `sanitize`, `stats`, `pack`, `serve`) encapsula uma etapa autônoma do ciclo de vida da documentação.
2. **Escreva programas para trabalharem juntos**: As saídas de um utilitário fluem naturalmente para a entrada de outro por meio de *pipes* (`|`) e redirecionamentos (`>`, `>>`, `<`).
3. **Trate o texto como a interface universal**: Em vez de binários opacos ou bancos de dados relacionais complexos, toda a informação é armazenada e manipulada como fluxos de texto Markdown puro e relatórios legíveis.

---

## Diagrama de Fluxo de Dados do Pipeline

O pipeline do Catalyst Shell Engine opera em **7 estágios sequenciais**, garantindo validação, higienização e empacotamento dos artefatos:

```mermaid
flowchart TD
    subgraph INGESTION ["1. Ingestão e Preparação"]
        A["📁 docs/*.md (Capítulos)"] --> B["⚙️ init_env & sort -V"]
        B --> C["📄 .concat_raw.tmp"]
    end

    subgraph PROCESSING ["2. Processamento Léxico & Parsing"]
        C --> D["🧹 sed Sanitizer (Higienização)"]
        D --> E["📄 dist/docs/full-document.md"]
        E --> F["📑 awk TOC Engine (Sumário 3 Níveis)"]
        F --> G["📄 dist/docs/summary.md"]
    end

    subgraph AUDIT ["3. Auditoria & Telemetria"]
        E --> H["🔍 grep -E Regex Link Auditor"]
        H --> I["✅ Validação de Ativos Locais"]
        E --> J["📊 wc & head/tail Metrics Engine"]
        J --> K["📄 dist/metrics/metrics.txt"]
    end

    subgraph ARTIFACTS ["4. Publicação & Distribuição"]
        E --> L["🌐 HTML5 Generator (Glassmorphism)"]
        G --> L
        K --> L
        L --> M["📄 dist/index.html"]
        
        E --> N["📦 tar + gzip Packager"]
        G --> N
        K --> N
        M --> N
        N --> O["🔒 chmod 755/644"]
        O --> P["🔑 SHA-256 Checksum Generator"]
        P --> Q["📦 dist/releases/catalyst-release-1.0.0.tar.gz"]
    end

    subgraph LIFECYCLE ["5. Gerenciamento de Processos"]
        Q --> R["🚀 Bash + OpenBSD netcat (background)"]
        R --> S["📋 Estado privado por usuario e projeto"]
        S --> T["🛑 kill -15 / kill -9 Termination"]
    end
```

---

## Detalhamento dos 7 Estágios do Pipeline

### Estágio 1: Preparação do Ambiente (`init_env`)
- Criação garantida do diretório de saída `dist/` com controle de erro (`mkdir -p "$DIST_DIR" || exit 1`).
- Definição de permissões octais estritas (`chmod 755 "$DIST_DIR"`).
- Criação do arquivo de métricas sem truncar resultados de subcomandos anteriores (`touch "$METRICS_FILE"`).

### Estágio 2: Consolidação e Sanitização Léxica (`consolidate_documents`)
- Varredura determinística de todos os capítulos via `sort -V` (ordenação natural que preserva a sequência `00`, `01`, `02`... `10`).
- Concatenação limpa com injeção de comentários semânticos (`<!-- Capitulo: ... -->`).
- Pipeline em **`sed -E`**:
  * Remoção cirúrgica de espaços e tabulações no final de linhas (`s/[ \t]+$//`).
  * Normalização do espaçamento de cabeçalhos Markdown, garantindo exatamente um espaço após a sequência de `#` (`s/^(#+)[ \t]+/\1 /`).

### Estágio 3: Extração de Sumário Hierárquico via AWK (`generate_toc`)
- O processamento de cabeçalhos Markdown é delegado a um programa completo em **AWK**:
  * Mantém acumuladores numéricos independentes para níveis H1, H2 e H3 (`h1`, `h2`, `h3`).
  * Gera numeração sequencial formatada (ex: `1.`, `1.1.`, `1.1.1.`).
  * Constrói âncoras (*slugs*) limpando caracteres especiais (`gsub(/[^a-z0-9_-]/, "", anchor)`).
  * Constrói âncoras (*slugs*) limpando caracteres especiais (`gsub(/[^a-z0-9_-]/, "", anchor)`).
  * Produz o arquivo `dist/docs/summary.md` com recuos proporcionais para navegação em árvore.

### Estágio 4: Auditoria de Links e Imagens com Expressões Regulares (`validate_assets_and_links`)
- Varre o documento unificado utilizando **`grep -E -o '\[[^]]+\]\(([^)]+)\)'`**.
- Filtra links externos (`http://`, `https://`) e âncoras locais (`#`), isolando referências a caminhos de arquivos relativos.
- Testa a existência de cada ativo local referenciado (`[ -f "$target" ] || [ -d "$target" ]`), retornando erro quando encontra referências quebradas. Âncoras do documento também são verificadas; exemplos em blocos e trechos de código são ignorados.

### Estágio 5: Cálculo Estatístico de Métricas e Integridade (`compute_statistics`)
- Extração de métricas quantitativas de volume utilizando `wc -l` (linhas) e `wc -w` (palavras).
- Amostragem instantânea de abertura e encerramento do compêndio via `head -n 3` e `tail -n 3`.
- Consolidação do relatório estruturado em `dist/metrics/metrics.txt`.

### Estágio 6: Geração de Interface Web Interativa com ChatBot (`generate_html_preview`)
- Criação autônoma do arquivo `dist/index.html` (único arquivo na raiz de distribuição).
- Interface moderna inspirada no sistema de design **GlassHub Quasar** (vidro fosco, tema escuro, variáveis CSS HSL, painel lateral responsivo e renderizador Markdown dinâmico com fallback).
- **Catalyst DocBot (Assistente Virtual Integrado)**: Motor local de recuperação de informação em Vanilla JS; as bibliotecas de renderização são carregadas por CDN, com busca por seções, deep linking, botões de ação e comandos de terminal (`/help`, `/conceitos`, `/stats`, `/benchmark`).

### Estágio 7: Empacotamento e Certificação de Release (`package_release`)
- Compactação e compressão gzip de todos os artefatos gerados (`tar -czf`).
- Atribuição de permissões simbólicas de segurança ao bundle (`chmod u=rw,go=r`).
- Geração automatizada de checksum SHA-256, com MD5 adicional por compatibilidade, salvando a assinatura em `dist/releases/catalyst-release-*.tar.gz.md5`.

---

## Organização de Diretórios e Componentes

```text
CatalystShellEngine/
├── catalyst.sh               # Orquestrador mestre e CLI unificada
├── docs/                     # Fonte primária da documentação técnica dividida em capítulos
│   ├── 00-cover.md           # Capa oficial e metadados institucionais
│   ├── 01-overview.md        # Visão geral, contexto do GlassHub e matriz de capacidades
│   ├── 02-architecture.md    # Engenharia do pipeline, diagrama Mermaid e estágios
│   ├── 03-concepts.md        # Detalhamento exaustivo dos 20 conceitos do enunciado
│   ├── 04-usage-guide.md     # Manual completo de operação da linha de comando
│   ├── 05-benchmarks.md      # Análise de performance vs. GlassHub Catalyst original
│   └── 06-conclusion.md      # Considerações finais, maturidade e roadmap
├── dist/                     # Diretório de distribuição compilado e certificado
│   ├── index.html            # Único arquivo na raiz: Interface web interativa + DocBot
│   ├── docs/                 # Subpasta de compilação textual unificada
│   │   ├── full-document.md  # Documento único consolidado e higienizado
│   │   └── summary.md        # Sumário hierárquico navegável gerado por AWK
│   ├── metrics/              # Subpasta de telemetria estatística
│   │   └── metrics.txt       # Relatório quantitativo de linhas e palavras (wc)
│   ├── reports/              # Subpasta de relatórios acadêmicos oficiais
│   │   └── sigaa-report.md   # Relatório unificado com código numerado para o SIGAA
│   └── releases/             # Subpasta de empacotamento e distribuição
│       ├── catalyst-release-*.tar.gz     # Bundle empacotado para distribuição
│       └── catalyst-release-*.tar.gz.md5 # Checksum MD5 de compatibilidade
├── scripts/                  # Biblioteca modular com componentes especializados
│   ├── core/                 # Módulos isolados de parsing, validação e sanitização
│   └── utils/                # Utilitários de logging colorido e formatação ANSI
└── CEFET_REPORT.md           # Relatório acadêmico oficial com planilha de conformidade
```

O orquestrador carrega os módulos de parser, sanitizer, validator, packager, preview, transação e completion; executa o servidor e o gerador acadêmico como processos externos. O HTML está em `templates/index.html`. A interface usa uma convenção própria de âncoras, distinta da convenção do GitHub.


## Staging, bloqueios e publicação

Os escritores compartilham `.catalyst/build.lock` e trabalham em diretórios staging
exclusivos. Só o snapshot concluído é publicado. Um segundo lock, `publish.lock`,
coordena o commit com as respostas do preview, sem bloquear a leitura durante o
processamento dos capítulos.

No Linux nativo, um rename troca o link `dist` para a geração concluída. A geração
anterior é mantida, e versões mais antigas são removidas sob o lock. A conversão
inicial de um `dist` legado é coordenada por esse mesmo lock.

No DrvFS do WSL, `dist` permanece um diretório compatível com Windows. Um journal
registra o commit em andamento e permite restaurar o backup após falha ou queda.
Nesse modo a consistência do snapshot depende do leitor respeitar `publish.lock`;
leitores externos podem observar arquivos de versões diferentes durante o commit.

O preview resolve a geração a cada requisição, para acompanhar builds novos sem
reiniciar o processo. `watch` adquire o lock apenas em cada build; não o retém
enquanto aguarda alterações.
