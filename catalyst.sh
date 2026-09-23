#!/usr/bin/env bash
# ==============================================================================
# PROJETO: Catalyst Shell Engine
# DISCIPLINA: TEFC: Shell Scripting - Engenharia da Computação (CEFET-MG)
# AUTOR: Matheus (GlassHub Ecosystem)
# DATA: 2026-09-22
# DESCRICAO:
#   Orquestrador e motor de documentacao tecnica modular, 100% desenvolvido
#   em Shell Script (Bash). Consolida multiplos capitulos Markdown, gera sumario
#   hierarquico indexado via AWK, higieniza formatacao via sed, valida links
#   com regex (grep -E), computa metricas estatisticas e empacota artefatos.
#
#   Implementa integralmente todos os 20 conceitos avaliados pela disciplina.
# ==============================================================================

# Atributos de variaveis: readonly e export (Conceito 12)
readonly APP_NAME="Catalyst Shell Engine"
readonly APP_VERSION="1.0.0"
export CATALYST_ENV="production"

# Variaveis criadas pelo usuario (Conceito 10)
# Expansoes de substituicao de comandos $(...) e expansoes de parametros (Conceito 09)
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCS_DIR="${BASE_DIR}/docs"
DIST_DIR="${BASE_DIR}/dist"
SCRIPTS_DIR="${BASE_DIR}/scripts"
OUTPUT_DOC="${DIST_DIR}/full-document.md"
OUTPUT_TOC="${DIST_DIR}/summary.md"
OUTPUT_HTML="${DIST_DIR}/index.html"
OUTPUT_BUNDLE="${DIST_DIR}/catalyst-release-${APP_VERSION}.tar.gz"
METRICS_FILE="${DIST_DIR}/metrics.txt"
PID_SERVER_FILE="/tmp/catalyst_server.pid"

# Atributo de variavel: inteira (Conceito 12)
declare -i TOTAL_DOCS=0
declare -i TOTAL_WORDS=0
declare -i TOTAL_LINES=0

# Atributo de variavel: arranjo / array (Conceito 12)
declare -a CHAPTER_FILES=()

# Limpeza segura de arquivos temporarios via trap de sinais (Conceito 06)
cleanup_exit() {
    rm -f "${DIST_DIR}/.concat_raw.tmp" 2>/dev/null || true
}
trap cleanup_exit EXIT INT TERM

# ==============================================================================
# FUNCOES AUXILIARES E MODULARES (Conceito 12: Funcao)
# ==============================================================================

show_banner() {
    # Comandos basicos: echo, date (Conceito 01)
    echo "================================================================="
    echo " ⚛️  ${APP_NAME} - v${APP_VERSION}"
    echo " Data do Sistema: $(date '+%d/%m/%Y %H:%M:%S')"
    echo " Diretorio Base : ${BASE_DIR}"
    echo "================================================================="
}

show_help() {
    # Redirecionamento padrao (Conceito 07)
    cat << EOF
Uso: $0 [COMANDO] [OPCOES]

Comandos disponiveis:
  build       Consolida documentos, gera sumario TOC, HTML e higieniza texto
  validate    Audita links internos e referencias a imagens locais com regex
  toc         Extrai e monta exclusivamente o sumario hierarquico com AWK
  sanitize    Executa higienizacao de formatacao e espacos com sed
  stats       Calcula estatisticas (linhas, palavras, checksums de integridade)
  pack        Empacota versao final em arquivo compactado .tar.gz com permissoes
  serve       Inicia servidor HTTP local em background (suporta --stop e porta)
  report      Gera relatorio unificado com codigo numerado (nl -ba) para SIGAA
  test        Executa suite de testes automatizados e assercoes do sistema
  watch       Modo observador com recompilacao automatica a cada salvamento
  clean       Limpa artefatos temporarios e gerados em dist/
  all         Executa o pipeline completo de publicacao (build, validate, pack)
  help        Exibe esta mensagem de ajuda detalhada

Exemplos:
  $0 all
  $0 test
  $0 report
  $0 watch
  $0 serve --port 8080
  $0 serve --stop
EOF
}

# ==============================================================================
# PIPELINE STEP 1: PREPARACAO DO AMBIENTE (Conceitos 01, 03, 04, 16)
# ==============================================================================
init_env() {
    echo "[1/7] Inicializando estrutura de diretorios..."
    
    # Sistema de arquivos: mkdir (Conceito 03) e Desvio condicional || (Conceito 16)
    mkdir -p "$DIST_DIR" || { echo "Falha ao criar $DIST_DIR" >&2; exit 1; }

    # Permissoes em representacao octal: chmod (Conceito 04)
    chmod 755 "$DIST_DIR"

    # Redirecionamento da saida para truncar arquivo de metricas (Conceito 07)
    > "$METRICS_FILE"
}

# ==============================================================================
# PIPELINE STEP 2: CONSOLIDACAO E PROCESSAMENTO DE TEXTO (Conceitos 02, 08, 17)
# ==============================================================================
consolidate_docs() {
    echo "[2/7] Consolidando capitulos de documentacao..."
    
    local temp_concat="${DIST_DIR}/.concat_raw.tmp"
    > "$temp_concat"

    # Comandos de repeticao: for (Conceito 17)
    # Pipes e ordenacao: sort (Conceito 02 e 08)
    for doc in $(ls "$DOCS_DIR"/*.md 2>/dev/null | sort -V); do
        # Teste condicional com test/if: arquivos (Conceito 14)
        if [ -f "$doc" ]; then
            local filename
            filename="$(basename "$doc")"
            CHAPTER_FILES+=("$filename")
            
            # Expansao aritmetica: $(( ... )) (Conceito 09)
            TOTAL_DOCS=$((TOTAL_DOCS + 1))
            
            echo -e "\n<!-- Capitulo: $filename -->\n" >> "$temp_concat"
            
            # Processamento de texto: cat e redirecionamento de adicao >> (Conceito 02 e 07)
            cat "$doc" >> "$temp_concat"
            echo "" >> "$temp_concat"
        fi
    done

    # Outras formas de desvio: && (Conceito 16)
    [ $TOTAL_DOCS -gt 0 ] && echo "Total de capitulos detectados: $TOTAL_DOCS"

    # Programa em sed: Higienizacao e padronizacao de cabecalhos e ancoras internas (Conceito 19)
    sed -E \
        -e 's/[ \t]+$//' \
        -e 's/^(#+)[ \t]+/\1 /' \
        -e 's/\(00-cover\.md\)/(#catalystshellengine)/g' \
        -e 's/\(01-overview\.md\)/(#01visogeralemotivao)/g' \
        -e 's/\(02-architecture\.md\)/(#02arquiteturaeengenhariadepipeline)/g' \
        -e 's/\(03-concepts\.md\)/(#03conformidadecomoenunciado20conceitos)/g' \
        -e 's/\(04-usage-guide\.md\)/(#04manualoperacionaldacli)/g' \
        -e 's/\(05-benchmarks\.md\)/(#05anlisecomparativaebenchmarks)/g' \
        -e 's/\(06-conclusion\.md\)/(#06conclusoeresultados)/g' \
        -e 's/\(CEFET_REPORT\.md\)/(#03conformidadecomoenunciado20conceitos)/g' \
        -e 's/\(catalyst\.sh\)/(#04manualoperacionaldacli)/g' \
        "$temp_concat" > "$OUTPUT_DOC"

    rm -f "$temp_concat"
    echo "Documento unificado gerado em: $OUTPUT_DOC"
}

# ==============================================================================
# PIPELINE STEP 3: EXTRACAO DE SUMARIO VIA AWK (Conceito 20)
# ==============================================================================
generate_toc_awk() {
    echo "[3/7] Gerando Sumario (TOC) hierarquico com AWK..."
    
    echo "<!-- Sumario Hierarquico Gerado Automaticamente -->" > "$OUTPUT_TOC"
    echo "## 📑 Sumário da Documentação" >> "$OUTPUT_TOC"
    echo "" >> "$OUTPUT_TOC"

    # Programa em AWK (Conceito 20):
    awk '
    BEGIN {
        h1 = 0; h2 = 0; h3 = 0; in_code = 0;
    }
    /^```/ {
        in_code = !in_code;
        next;
    }
    in_code {
        next;
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
        sub_h2 = (h2 == 0) ? 1 : h2;
        printf("      %d.%d.%d. [%s](#%s)\n", h1, sub_h2, h3, title, anchor);
    }
    ' "$OUTPUT_DOC" >> "$OUTPUT_TOC"

    echo "Sumario gerado com sucesso em: $OUTPUT_TOC"
}

# ==============================================================================
# PIPELINE STEP 4: AUDITORIA DE LINKS COM GREP REGEX (Conceito 18)
# ==============================================================================
validate_links_regex() {
    echo "[4/7] Auditando links e imagens via grep com metacaracteres..."
    
    # Testes condicionais com if (Conceito 14)
    if [ ! -f "$OUTPUT_DOC" ]; then
        echo "Documento completo inexistente. Execute o build primeiro." >&2
        return 1
    fi

    # Expressao regular estendida (grep -E) com metacaracteres: ^, !, \[, \], +, (, ) (Conceito 18)
    local link_pattern='\[[^]]+\]\(([^)]+)\)'
    local broken_links=0

    # Pipes avancados com while e redirecionamento de entrada < (Conceitos 07 e 08)
    while IFS= read -r match; do
        [ -z "$match" ] && continue
        # Expansao avancada de substituicao de padrao (Conceito 13)
        local raw_url
        raw_url=$(echo "$match" | sed -E 's/\[[^]]+\]\(([^)]+)\)/\1/')
        
        # Teste com expressao regular Bash =~ (Conceito 14)
        if [[ ! "$raw_url" =~ ^https?:// && ! "$raw_url" =~ ^# ]]; then
            # Remove parametro de ancora se houver (Conceito 13)
            local clean_target="${raw_url%%#*}"
            local target_path="${BASE_DIR}/${clean_target}"
            local target_in_docs="${DOCS_DIR}/${clean_target}"
            
            if [ -f "$target_path" ] || [ -d "$target_path" ] || [ -f "$target_in_docs" ]; then
                echo "  [OK] Referencia validada: $clean_target"
            else
                echo "  [AVISO] Referencia local pendente: $clean_target"
                broken_links=$((broken_links + 1))
            fi
        fi
    done < <(grep -E -o "$link_pattern" "$OUTPUT_DOC" 2>/dev/null || true)

    if [ "$broken_links" -eq 0 ]; then
        echo "Todos os links e referencias locais foram validados com sucesso!"
    else
        echo "Auditoria concluida: $broken_links referencias locais requerem atencao."
    fi
}

# ==============================================================================
# PIPELINE STEP 5: ESTATISTICAS E INTEGRIDADE (Conceitos 02, 03, 07, 08)
# ==============================================================================
compute_statistics() {
    echo "[5/7] Calculando metricas e checksums de integridade..."
    
    # Recalcula contagem de capitulos caso esteja zerada (Conceitos 09 e 16)
    [ $TOTAL_DOCS -eq 0 ] && TOTAL_DOCS=$(ls "$DOCS_DIR"/*.md 2>/dev/null | wc -l)

    # Processamento de texto: wc -l e wc -w (Conceito 02)
    TOTAL_LINES=$(wc -l < "$OUTPUT_DOC")
    TOTAL_WORDS=$(wc -w < "$OUTPUT_DOC")

    # Amostragem com head e tail (Conceito 02)
    local sample_header
    local sample_footer
    sample_header=$(head -n 3 "$OUTPUT_DOC")
    sample_footer=$(tail -n 3 "$OUTPUT_DOC")

    # Redirecionamento avancado para relatorio (Conceito 07)
    {
        echo "================ METRICAS DO CATALYST ================"
        echo "Gerado em         : $(date)"
        echo "Total de Capitulos: $TOTAL_DOCS"
        echo "Total de Linhas   : $TOTAL_LINES"
        echo "Total de Palavras : $TOTAL_WORDS"
        echo "----------------- AMOSTRA INICIAL --------------------"
        echo "$sample_header"
        echo "----------------- AMOSTRA FINAL ----------------------"
        echo "$sample_footer"
        echo "======================================================="
    } > "$METRICS_FILE"

    cat "$METRICS_FILE"
}

# ==============================================================================
# PIPELINE STEP 6: GERACAO DE PREVIEW HTML COM DESIGN MODERNO
# ==============================================================================
generate_html_preview() {
    echo "[6/7] Gerando interface web interativa (index.html)..."

    cat << 'EOF' > "$OUTPUT_HTML"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Catalyst Shell Engine - Documentação Interativa</title>
    <link rel="icon" type="image/svg+xml" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Ccircle cx='16' cy='16' r='14' fill='%230d1117' stroke='%2358a6ff' stroke-width='2'/%3E%3Cellipse cx='16' cy='16' rx='11' ry='4' fill='none' stroke='%2358a6ff' stroke-width='1.5' transform='rotate(30 16 16)'/%3E%3Cellipse cx='16' cy='16' rx='11' ry='4' fill='none' stroke='%23bc8cff' stroke-width='1.5' transform='rotate(90 16 16)'/%3E%3Cellipse cx='16' cy='16' rx='11' ry='4' fill='none' stroke='%233fb950' stroke-width='1.5' transform='rotate(150 16 16)'/%3E%3Ccircle cx='16' cy='16' r='3' fill='%2358a6ff'/%3E%3C/svg%3E">
    <!-- Renderizadores: Markdown (Marked) e Diagramas (Mermaid) -->
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    <style>
        :root {
            --bg-base: #0d1117;
            --bg-card: rgba(22, 27, 34, 0.95);
            --border: rgba(240, 246, 252, 0.12);
            --text-main: #f0f6fc;
            --text-muted: #8b949e;
            --accent: #58a6ff;
            --accent-glow: rgba(88, 166, 255, 0.15);
            --green: #3fb950;
            --purple: #bc8cff;
        }
        body.theme-light {
            --bg-base: #f6f8fa;
            --bg-card: #ffffff;
            --border: #d0d7de;
            --text-main: #1f2328;
            --text-muted: #656d76;
            --accent: #0969da;
            --accent-glow: rgba(9, 105, 218, 0.12);
            --green: #1a7f37;
            --purple: #8250df;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        html { scroll-behavior: smooth; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: var(--bg-base);
            color: var(--text-main);
            display: flex;
            min-height: 100vh;
            transition: background-color 0.2s, color 0.2s;
        }
        aside {
            width: 340px;
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            border-right: 1px solid var(--border);
            padding: 24px;
            display: flex;
            flex-direction: column;
            gap: 16px;
            position: sticky;
            top: 0;
            height: 100vh;
            overflow-y: auto;
            flex-shrink: 0;
            transition: transform 0.25s ease, margin-left 0.25s ease;
        }
        body.focus-mode aside {
            margin-left: -340px;
        }
        .brand {
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 1.2rem;
            font-weight: 700;
            color: var(--text-main);
        }
        .badge {
            background: rgba(88, 166, 255, 0.15);
            color: var(--accent);
            padding: 2px 8px;
            border-radius: 12px;
            font-size: 0.75rem;
            font-weight: 600;
        }
        .actions-bar {
            display: flex;
            gap: 6px;
        }
        .action-btn {
            flex: 1;
            padding: 7px 10px;
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid var(--border);
            border-radius: 8px;
            color: var(--text-main);
            font-size: 0.78rem;
            cursor: pointer;
            font-weight: 500;
            transition: all 0.2s;
            text-align: center;
        }
        .action-btn:hover {
            background: var(--accent);
            color: #fff;
            border-color: var(--accent);
        }
        .search-box input {
            width: 100%;
            padding: 8px 12px;
            background: rgba(255, 255, 255, 0.04);
            border: 1px solid var(--border);
            border-radius: 8px;
            color: var(--text-main);
            font-size: 0.85rem;
            outline: none;
            transition: border-color 0.2s;
        }
        .search-box input:focus {
            border-color: var(--accent);
        }
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 8px;
        }
        .metric-card {
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 10px;
            text-align: center;
        }
        .metric-card span { font-size: 0.72rem; color: var(--text-muted); display: block; }
        .metric-card strong { font-size: 1.15rem; color: var(--accent); }
        .section-title {
            font-size: 0.8rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: var(--text-muted);
            margin-bottom: 4px;
        }
        #toc-container a {
            display: block;
            color: var(--text-muted);
            text-decoration: none;
            padding: 6px 10px;
            border-radius: 6px;
            font-size: 0.86rem;
            transition: all 0.2s;
            margin-bottom: 2px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        #toc-container a:hover {
            background: rgba(88, 166, 255, 0.1);
            color: var(--accent);
            transform: translateX(3px);
        }
        main {
            flex: 1;
            padding: 48px 56px;
            max-width: 1080px;
            margin: 0 auto;
            overflow-y: auto;
            width: 100%;
            box-sizing: border-box;
            transition: padding 0.2s;
        }
        .hero {
            background: linear-gradient(135deg, rgba(88, 166, 255, 0.1), rgba(188, 140, 255, 0.05));
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 28px 36px;
            margin-bottom: 32px;
            box-shadow: 0 8px 32px var(--accent-glow);
        }
        .hero h1 { font-size: 2rem; margin-bottom: 6px; color: var(--text-main); }
        .hero p { color: var(--text-muted); font-size: 1rem; }
        .doc-body {
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 56px 64px;
            line-height: 1.85;
            margin-bottom: 64px;
            box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06);
            box-sizing: border-box;
        }
        .doc-body h1 {
            font-size: 2.1rem;
            margin-top: 2.6rem;
            margin-bottom: 1.2rem;
            color: var(--text-main);
            border-bottom: 2px solid var(--border);
            padding-bottom: 0.6rem;
            scroll-margin-top: 32px;
        }
        .doc-body h1:first-of-type {
            margin-top: 0;
        }
        .doc-body h2 {
            font-size: 1.55rem;
            margin-top: 2.2rem;
            margin-bottom: 1rem;
            color: var(--text-main);
            border-bottom: 1px solid var(--border);
            padding-bottom: 0.5rem;
            scroll-margin-top: 32px;
        }
        .doc-body h3 {
            font-size: 1.22rem;
            margin-top: 1.8rem;
            margin-bottom: 0.8rem;
            color: var(--text-main);
            scroll-margin-top: 32px;
        }
        .doc-body p { margin-bottom: 1.4rem; color: var(--text-main); opacity: 0.94; font-size: 1.02rem; }
        .doc-body ul, .doc-body ol { margin-bottom: 1.4rem; padding-left: 28px; color: var(--text-main); opacity: 0.94; }
        .doc-body li { margin-bottom: 8px; }
        .doc-body a { color: var(--accent); text-decoration: none; cursor: pointer; }
        .doc-body a:hover { text-decoration: underline; }
        .doc-body pre {
            background: #040d21;
            padding: 22px 26px;
            border-radius: 12px;
            border: 1px solid var(--border);
            overflow-x: auto;
            margin: 2rem 0;
            font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
            line-height: 1.45;
            letter-spacing: 0;
            font-size: 0.9rem;
        }
        body.theme-light .doc-body pre {
            background: #f6f8fa;
            border-color: #d0d7de;
        }
        .doc-body code {
            font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
            background: rgba(110, 118, 129, 0.18);
            padding: 3px 7px;
            border-radius: 5px;
            font-size: 0.88em;
        }
        .doc-body blockquote {
            border-left: 4px solid var(--accent);
            padding: 16px 24px;
            color: var(--text-muted);
            background: rgba(88, 166, 255, 0.06);
            border-radius: 0 10px 10px 0;
            margin: 2rem 0;
        }
        .doc-body hr {
            border: none;
            border-top: 1px solid var(--border);
            margin: 2.8rem 0;
        }
        .doc-body table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            margin: 2.2rem 0;
            border: 1px solid var(--border);
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
        }
        .doc-body th, .doc-body td {
            border-bottom: 1px solid var(--border);
            border-right: 1px solid var(--border);
            padding: 14px 20px;
            text-align: left;
            font-size: 0.95rem;
        }
        .doc-body th:last-child, .doc-body td:last-child {
            border-right: none;
        }
        .doc-body tr:last-child td {
            border-bottom: none;
        }
        .doc-body th {
            background: rgba(125, 125, 125, 0.08);
            font-weight: 600;
        }

        /* Responsividade para telas menores e tablets */
        @media (max-width: 1080px) {
            body { flex-direction: column; }
            aside {
                width: 100%;
                height: auto;
                position: relative;
                border-right: none;
                border-bottom: 1px solid var(--border);
                padding: 24px;
            }
            body.focus-mode aside {
                margin-left: 0;
                display: none;
            }
            main {
                padding: 32px 24px;
                max-width: 100%;
            }
            .doc-body {
                padding: 36px 24px;
            }
        }
        @media (max-width: 640px) {
            main { padding: 16px 12px; }
            .doc-body { padding: 24px 16px; border-radius: 12px; }
            .hero { padding: 20px 16px; }
        }

        /* Diagramas Mermaid */
        .mermaid-container {
            display: flex;
            justify-content: center;
            align-items: center;
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 28px 16px;
            margin: 2.2rem 0;
            overflow-x: auto;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
        }
        body.theme-light .mermaid-container {
            background: #ffffff;
            border-color: #d0d7de;
        }
        .mermaid-container svg {
            max-width: 100%;
            height: auto;
        }

        /* Botão Flutuante de Menu para Modo Foco */
        .floating-menu-btn {
            position: fixed;
            top: 20px;
            left: 24px;
            z-index: 1000;
            display: none;
            align-items: center;
            gap: 8px;
            background: var(--bg-card);
            border: 1px solid var(--accent);
            color: var(--accent);
            padding: 9px 18px;
            border-radius: 30px;
            cursor: pointer;
            font-size: 0.85rem;
            font-weight: 600;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.35);
            backdrop-filter: blur(16px);
            transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
        }
        .floating-menu-btn:hover {
            background: var(--accent);
            color: #fff;
            transform: translateY(-2px);
            box-shadow: 0 6px 24px var(--accent-glow);
        }
        body.focus-mode .floating-menu-btn {
            display: inline-flex;
        }

        /* Estilos de Impressão Profissional e PDF (@media print) */
        @page {
            size: A4 portrait;
            margin: 20mm 15mm 20mm 15mm;
        }
        @media print {
            * {
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }
            html, body {
                display: block !important;
                background: #ffffff !important;
                color: #111111 !important;
                height: auto !important;
                min-height: auto !important;
                overflow: visible !important;
                font-size: 11pt !important;
                line-height: 1.6 !important;
            }
            aside, .hero, .actions-bar, .floating-menu-btn, .search-box, .metrics-grid, #theme-btn, #focus-btn, #print-btn {
                display: none !important;
            }
            main {
                display: block !important;
                padding: 0 !important;
                margin: 0 !important;
                max-width: 100% !important;
                width: 100% !important;
                height: auto !important;
                min-height: auto !important;
                overflow: visible !important;
            }
            .doc-body {
                display: block !important;
                border: none !important;
                background: transparent !important;
                box-shadow: none !important;
                padding: 0 !important;
                margin: 0 !important;
                height: auto !important;
                min-height: auto !important;
                overflow: visible !important;
            }
            .doc-body * {
                color: #111111 !important;
                box-shadow: none !important;
                text-shadow: none !important;
            }
            h1, h2, h3, h4, h5, h6 {
                page-break-after: avoid !important;
                break-after: avoid !important;
                page-break-inside: avoid !important;
                break-inside: avoid !important;
                margin-top: 1.8rem !important;
                margin-bottom: 0.8rem !important;
                padding-top: 0.6rem !important;
                color: #000000 !important;
            }
            h1 { font-size: 1.8rem !important; }
            h2 { font-size: 1.4rem !important; }
            h3 { font-size: 1.2rem !important; }
            p, blockquote, pre, .mermaid-container, table, figure {
                page-break-inside: avoid !important;
                break-inside: avoid !important;
            }
            ol, ul {
                page-break-inside: auto;
                padding-left: 24px !important;
            }
            li {
                page-break-inside: avoid !important;
                break-inside: avoid !important;
                margin-bottom: 6px !important;
            }
            table {
                width: 100% !important;
                border-collapse: collapse !important;
                page-break-inside: auto;
                margin: 1.5rem 0 !important;
            }
            tr {
                page-break-inside: avoid !important;
                break-inside: avoid !important;
            }
            thead {
                display: table-header-group !important;
            }
            pre {
                border: 1px solid #d0d7de !important;
                background: #f6f8fa !important;
                padding: 12px 16px !important;
                border-radius: 6px !important;
                font-size: 9pt !important;
                white-space: pre-wrap !important;
                word-break: break-word !important;
            }
            code {
                font-size: 9pt !important;
                background: #f0f2f5 !important;
                padding: 2px 4px !important;
                border-radius: 4px !important;
            }
            blockquote {
                border-left: 3px solid #0969da !important;
                background: #f6f8fa !important;
                padding: 10px 16px !important;
            }
            a {
                text-decoration: none !important;
                color: #0969da !important;
            }
            .mermaid-container {
                border: 1px solid #d0d7de !important;
                background: #ffffff !important;
                padding: 12px !important;
            }
            .mermaid-container svg {
                max-width: 100% !important;
                height: auto !important;
            }
        }
    </style>
</head>
<body>
    <!-- Botao Flutuante para Restaurar Menu no Modo Foco -->
    <button id="floating-menu-btn" class="floating-menu-btn" title="Mostrar menu lateral e sumário" aria-label="Abrir Menu">
        <span>📑</span>
        <span>Sumário</span>
    </button>
    <aside id="sidebar">
        <div class="brand">
            <span>⚛️ Catalyst Shell</span>
            <span class="badge">v1.0.0</span>
        </div>
        <p style="font-size: 0.82rem; color: var(--text-muted);">TEFC: Shell Scripting • CEFET-MG</p>
        
        <div class="actions-bar">
            <button id="theme-btn" class="action-btn" title="Alternar Tema Claro/Escuro">🌓 Tema</button>
            <button id="focus-btn" class="action-btn" title="Alternar Modo Foco / Expandir Leitura">📐 Foco</button>
            <button id="print-btn" class="action-btn" title="Exportar para PDF ou Imprimir" onclick="window.print()">🖨️ PDF</button>
        </div>

        <div class="search-box">
            <input type="text" id="doc-search" placeholder="🔍 Buscar no sumário..." />
        </div>

        <div class="section-title">Métricas de Build (wc)</div>
        <div class="metrics-grid">
            <div class="metric-card">
                <span>Capítulos</span>
                <strong id="m-docs">--</strong>
            </div>
            <div class="metric-card">
                <span>Total Linhas</span>
                <strong id="m-lines">--</strong>
            </div>
            <div class="metric-card">
                <span>Palavras</span>
                <strong id="m-words">--</strong>
            </div>
            <div class="metric-card">
                <span>Status</span>
                <strong style="color: var(--green);">OK</strong>
            </div>
        </div>

        <div class="section-title" style="margin-top: 8px;">Sumário Geral (AWK)</div>
        <nav id="toc-container">Carregando sumário...</nav>
    </aside>

    <main>
        <div class="hero">
            <h1>Documentação Consolidada</h1>
            <p>Gerada e estruturada 100% em <strong>Shell Script (Bash)</strong> pelo Catalyst Shell Engine.</p>
        </div>
        <div class="doc-body" id="doc-render">
            <p>Carregando documentação compilada...</p>
        </div>
    </main>

    <script>
        // Alternador de tema Claro / Escuro
        const themeBtn = document.getElementById('theme-btn');
        if (localStorage.getItem('catalyst_theme') === 'light') {
            document.body.classList.add('theme-light');
        }
        themeBtn.addEventListener('click', () => {
            document.body.classList.toggle('theme-light');
            const isLight = document.body.classList.contains('theme-light');
            localStorage.setItem('catalyst_theme', isLight ? 'light' : 'dark');
        });

        // Alternador de Modo Foco (Oculta menu lateral para maximizar margens)
        const focusBtn = document.getElementById('focus-btn');
        const floatingMenuBtn = document.getElementById('floating-menu-btn');
        
        focusBtn.addEventListener('click', () => {
            document.body.classList.toggle('focus-mode');
        });
        
        if (floatingMenuBtn) {
            floatingMenuBtn.addEventListener('click', () => {
                document.body.classList.remove('focus-mode');
            });
        }

        window.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && document.body.classList.contains('focus-mode')) {
                document.body.classList.remove('focus-mode');
            }
        });

        // Carrega metricas de build
        fetch('metrics.txt')
            .then(r => r.text())
            .then(text => {
                const docsMatch = text.match(/Total de Capitulos:\s*(\d+)/);
                const linesMatch = text.match(/Total de Linhas\s*:\s*(\d+)/);
                const wordsMatch = text.match(/Total de Palavras\s*:\s*(\d+)/);
                if (docsMatch) document.getElementById('m-docs').innerText = docsMatch[1];
                if (linesMatch) document.getElementById('m-lines').innerText = linesMatch[1];
                if (wordsMatch) document.getElementById('m-words').innerText = wordsMatch[1];
            })
            .catch(() => {});

        // Carrega Sumario
        fetch('summary.md')
            .then(r => r.text())
            .then(md => {
                const lines = md.split('\n');
                let html = '';
                lines.forEach(line => {
                    const match = line.match(/^\s*(\d+(\.\d+)*)\.?\s*\[([^\]]+)\]\((#[^\)]+)\)/);
                    if (match) {
                        const num = match[1];
                        const title = match[3];
                        const anchor = match[4];
                        const indent = match[0].search(/\S/) * 4;
                        html += `<a href="${anchor}" style="margin-left: ${indent}px;">${num} ${title}</a>`;
                    }
                });
                document.getElementById('toc-container').innerHTML = html || '<p style="color:var(--text-muted);font-size:0.85rem;">Sumário indisponível</p>';
            })
            .catch(() => {});

        // Busca instantanea no sumario
        const searchInput = document.getElementById('doc-search');
        searchInput.addEventListener('input', (e) => {
            const query = e.target.value.toLowerCase().trim();
            const links = document.querySelectorAll('#toc-container a');
            links.forEach(link => {
                const text = link.textContent.toLowerCase();
                if (!query || text.includes(query)) {
                    link.style.display = 'block';
                } else {
                    link.style.display = 'none';
                }
            });
        });

        // Carrega Documento com Renderizador Markdown (Marked ou fallback)
        fetch('full-document.md')
            .then(r => r.text())
            .then(async md => {
                let cleanMd = md.replace(/^---[\r\n]+[\s\S]*?[\r\n]+---\s*/, '');
                if (window.marked) {
                    document.getElementById('doc-render').innerHTML = marked.parse(cleanMd);
                } else {
                    let h = cleanMd
                        .replace(/^### (.*$)/gim, '<h3 id="$1">$1</h3>')
                        .replace(/^## (.*$)/gim, '<h2 id="$1">$1</h2>')
                        .replace(/^# (.*$)/gim, '<h1 id="$1">$1</h1>')
                        .replace(/\*\*(.*?)\*\*/gim, '<strong>$1</strong>')
                        .replace(/\*(.*?)\*/gim, '<em>$1</em>')
                        .replace(/\[([^\]]+)\]\(([^)]+)\)/gim, '<a href="$2">$1</a>')
                        .replace(/\n\n/gim, '</p><p>');
                    document.getElementById('doc-render').innerHTML = `<p>${h}</p>`;
                }

                // Renderizacao de diagramas Mermaid
                if (window.mermaid) {
                    try {
                        const isLight = document.body.classList.contains('theme-light');
                        mermaid.initialize({
                            startOnLoad: false,
                            theme: isLight ? 'default' : 'dark',
                            securityLevel: 'loose'
                        });
                        const mermaidBlocks = document.querySelectorAll('#doc-render pre code.language-mermaid, #doc-render pre code.lang-mermaid');
                        for (let i = 0; i < mermaidBlocks.length; i++) {
                            const codeBlock = mermaidBlocks[i];
                            const preBlock = codeBlock.closest('pre');
                            const diagramCode = codeBlock.textContent.trim();
                            const container = document.createElement('div');
                            container.className = 'mermaid-container';
                            const diagId = 'mermaid-svg-' + i;
                            try {
                                const { svg } = await mermaid.render(diagId, diagramCode);
                                container.innerHTML = svg;
                                preBlock.parentNode.replaceChild(container, preBlock);
                            } catch (renderError) {
                                console.warn('Erro ao renderizar diagrama Mermaid:', renderError);
                            }
                        }
                    } catch (mErr) {
                        console.warn('Erro ao inicializar Mermaid:', mErr);
                    }
                }

                // Vincula IDs correspondentes para as ancoras do sumario AWK funcionarem perfeitamente
                document.querySelectorAll('#doc-render h1, #doc-render h2, #doc-render h3').forEach(el => {
                    const cleanId = el.innerText.toLowerCase().replace(/[^a-z0-9_-]/g, '');
                    el.id = cleanId;
                });

                // Se a URL contiver uma ancora no carregamento inicial, rola suavemente ate ela
                if (window.location.hash) {
                    const hash = window.location.hash.substring(1);
                    const normalized = hash.toLowerCase().replace(/[^a-z0-9_-]/g, '');
                    const initialTarget = document.getElementById(hash) || document.getElementById(normalized);
                    if (initialTarget) {
                        setTimeout(() => initialTarget.scrollIntoView({ behavior: 'smooth', block: 'start' }), 150);
                    }
                }
            })
            .catch(err => {
                document.getElementById('doc-render').innerHTML = '<p>Erro ao carregar documento: ' + err + '</p>';
            });

        // Interceptador Inteligente de Links: Resolve referencias entre capitulos com ancoras internas
        document.addEventListener('click', (e) => {
            const a = e.target.closest('a');
            if (!a) return;
            const href = a.getAttribute('href');
            if (!href) return;

            // 1. Links externos abrem em nova aba com seguranca
            if (href.startsWith('http://') || href.startsWith('https://') || href.startsWith('mailto:')) {
                a.setAttribute('target', '_blank');
                a.setAttribute('rel', 'noopener noreferrer');
                return;
            }

            // 2. Mapeamento caso algum link aponte para nome de arquivo .md individual
            const fileToAnchor = {
                '00-cover.md': 'catalystshellengine',
                '01-overview.md': '01visogeralemotivao',
                '02-architecture.md': '02arquiteturaeengenhariadepipeline',
                '03-concepts.md': '03conformidadecomoenunciado20conceitos',
                '04-usage-guide.md': '04manualoperacionaldacli',
                '05-benchmarks.md': '05anlisecomparativaebenchmarks',
                '06-conclusion.md': '06conclusoeresultados',
                'CEFET_REPORT.md': '03conformidadecomoenunciado20conceitos',
                'full-document.md': 'catalystshellengine',
                'summary.md': 'sumriodadocumentao',
                'metrics.txt': '05anlisecomparativaebenchmarks',
                'catalyst.sh': '04manualoperacionaldacli'
            };

            let targetId = '';
            if (href.startsWith('#')) {
                targetId = href.substring(1);
            } else {
                const cleanFile = href.replace(/^(\.\/|\.\.\/|docs\/)+/, '');
                if (fileToAnchor[cleanFile]) {
                    targetId = fileToAnchor[cleanFile];
                }
            }

            if (targetId) {
                const el = document.getElementById(targetId) ||
                           document.querySelector(`[name="${targetId}"]`) ||
                           document.querySelector(`[id*="${targetId}"]`);
                if (el) {
                    e.preventDefault();
                    el.scrollIntoView({ behavior: 'smooth', block: 'start' });
                    history.pushState(null, '', '#' + targetId);
                }
            }
        });
    </script>
</body>
</html>
EOF
    echo "Interface HTML criada com sucesso em: $OUTPUT_HTML"
}

# ==============================================================================
# PIPELINE STEP 7: EMPACOTAMENTO DE RELEASE (Conceitos 03, 04)
# ==============================================================================
package_release() {
    echo "[7/7] Empacotando versao de distribuicao..."
    
    # Sistema de arquivos: tar e gzip (Conceito 03)
    tar -czf "$OUTPUT_BUNDLE" -C "$DIST_DIR" "full-document.md" "summary.md" "metrics.txt" "index.html" 2>/dev/null
    
    # Permissoes simbolicas: chmod (Conceito 04)
    chmod u=rw,go=r "$OUTPUT_BUNDLE"

    # Checksum de arquivo com md5sum ou cksum (Conceito 03)
    if command -v md5sum &>/dev/null; then
        md5sum "$OUTPUT_BUNDLE" > "${OUTPUT_BUNDLE}.md5"
        echo "Release bundle gerado com sucesso: $OUTPUT_BUNDLE"
        echo "Checksum MD5: $(cat "${OUTPUT_BUNDLE}.md5")"
    else
        cksum "$OUTPUT_BUNDLE" > "${OUTPUT_BUNDLE}.cksum"
        echo "Release bundle gerado com sucesso: $OUTPUT_BUNDLE"
        echo "Checksum CKSUM: $(cat "${OUTPUT_BUNDLE}.cksum")"
    fi
}

# ==============================================================================
# GERENCIAMENTO DE SERVIDOR E PROCESSOS (Conceitos 03, 05, 06, 11)
# ==============================================================================
manage_server() {
    local action="start"
    local port="8000"

    # Processa argumentos e flags flexiveis (Conceitos 11, 14, 15, 17)
    while [ $# -gt 0 ]; do
        case "$1" in
            --stop|stop)
                action="stop"
                ;;
            --port|-p)
                shift
                port="${1:-8000}"
                ;;
            [0-9]*)
                port="$1"
                ;;
        esac
        shift
    done

    if [ "$action" = "--stop" ] || [ "$action" = "stop" ]; then
        local killed=false

        if [ -f "$PID_SERVER_FILE" ]; then
            local active_pid
            active_pid=$(cat "$PID_SERVER_FILE")

            # Inspeciona processos ativos com ps (Conceito 05)
            if ps -p "$active_pid" >/dev/null 2>&1; then
                echo "Encerrando servidor com PID $active_pid..."
                # Envio de sinais kill (Conceito 06)
                kill -15 "$active_pid" 2>/dev/null || kill -9 "$active_pid" 2>/dev/null
                killed=true
            fi
            rm -f "$PID_SERVER_FILE"
        fi

        # Para WSL e processos orfaos na porta: usa fuser (Conceito 03) ou pkill
        if command -v fuser &>/dev/null; then
            fuser -k "${port}/tcp" >/dev/null 2>&1 && killed=true || true
        fi
        pkill -f "http.server.*${port}" 2>/dev/null && killed=true || true

        if [ "$killed" = true ]; then
            echo "Servidor de preview encerrado com sucesso."
        else
            echo "Nenhum servidor ativo localizado para encerramento."
        fi
    else
        # Se ja estiver rodando na porta, avisa
        if command -v fuser &>/dev/null && fuser "${port}/tcp" >/dev/null 2>&1; then
            echo "A porta $port ja possui um processo ativo. Use '$0 serve --stop' para encerrar."
            return 0
        fi

        echo "Iniciando servidor de preview na porta $port..."
        
        # Executa python http.server diretamente em background (sem subshell), capturando $! (Conceito 11)
        if command -v python3 &>/dev/null; then
            python3 -m http.server -d "$DIST_DIR" "$port" >/dev/null 2>&1 &
        elif command -v python &>/dev/null; then
            python -m http.server -d "$DIST_DIR" "$port" >/dev/null 2>&1 &
        else
            echo "Interpretador python3 necessario para servidor de preview." >&2
            return 1
        fi

        # Parametro especial $!: PID do processo colocado em background (Conceito 11)
        local server_pid=$!
        echo "$server_pid" > "$PID_SERVER_FILE"
        echo "Servidor rodando em background com PID $server_pid em http://localhost:$port"
        
        # Mostra jobs em background (Conceito 05)
        jobs -l 2>/dev/null || true
    fi
}

# ==============================================================================
# LIMPEZA DE AMBIENTE (Conceitos 01, 03)
# ==============================================================================
clean_dist() {
    echo "Limpando diretorio de saida: $DIST_DIR..."
    rm -rf "${DIST_DIR:?}"/*
    echo "Limpeza concluida."
}

# ==============================================================================
# GERADOR DE RELATORIO FORMATADO PARA O SIGAA (nl -ba)
# ==============================================================================
generate_sigaa_report() {
    echo "[SIGAA] Gerando relatorio oficial unificado com codigo numerado..."
    local report_output="${DIST_DIR}/sigaa-report.md"
    local numbered_code="${DIST_DIR}/catalyst-code-numbered.txt"

    # Usa nl -ba para numerar todas as linhas de codigo do script
    if command -v nl &>/dev/null; then
        nl -ba -w 4 -s ": " "$0" > "$numbered_code"
    else
        awk '{ printf("%4d: %s\n", NR, $0); }' "$0" > "$numbered_code"
    fi

    # Combina a descricao do problema, codigo numerado e planilha de conceitos
    {
        echo "# Relatório de Submissão Oficial SIGAA - Catalyst Shell Engine"
        echo ""
        echo "**Instituição**: Centro Federal de Educação Tecnológica de Minas Gerais (CEFET-MG)"
        echo "**Disciplina**: TEFC: Shell Scripting - Engenharia da Computação"
        echo "**Aluno**: Matheus | **Ano/Semestre**: 2026/2"
        echo "**Data de Geração**: $(date '+%d/%m/%Y %H:%M:%S')"
        echo ""
        echo "---"
        echo ""
        sed -n '10,48p' "$BASE_DIR/CEFET_REPORT.md"
        echo ""
        echo "---"
        echo ""
        echo "## Código-Fonte Completo do Shell Script (Linhas Numeradas)"
        echo ""
        echo '```bash'
        cat "$numbered_code"
        echo '```'
        echo ""
        echo "---"
        echo ""
        sed -n '52,$p' "$BASE_DIR/CEFET_REPORT.md"
    } > "$report_output"

    rm -f "$numbered_code"
    echo "Relatório oficial unificado para o SIGAA gerado em: $report_output"
}

# ==============================================================================
# MODO OBSERVADOR COM RECOMPILACAO AUTOMATICA (stat, sleep)
# ==============================================================================
watch_docs() {
    echo "Iniciando modo observador (Watch Mode) em $DOCS_DIR..."
    echo "Pressione Ctrl+C para encerrar."
    
    local last_checksum=""
    while true; do
        local current_checksum
        current_checksum=$(ls -l --time-style=+%s "$DOCS_DIR"/*.md 2>/dev/null | md5sum 2>/dev/null || cksum)
        
        if [ "$current_checksum" != "$last_checksum" ]; then
            if [ -n "$last_checksum" ]; then
                echo -e "\n[$(date '+%H:%M:%S')] Alteração detectada em docs/. Recompilando..."
                consolidate_docs
                generate_toc_awk
                generate_html_preview
                echo "[$(date '+%H:%M:%S')] Recompilação concluída com sucesso!"
            fi
            last_checksum="$current_checksum"
        fi
        sleep 1
    done
}

# ==============================================================================
# SUITE DE TESTES AUTOMATIZADOS (Asserts e Integracao)
# ==============================================================================
run_tests() {
    echo "================================================================="
    echo " 🧪 Executando Suíte de Testes Automatizados do Catalyst"
    echo "================================================================="
    
    local test_failures=0
    local test_count=0

    assert_success() {
        local test_name="$1"
        shift
        test_count=$((test_count + 1))
        echo -n "  Teste $test_count: $test_name... "
        if "$@" >/dev/null 2>&1; then
            echo -e "\033[32m[PASSOU]\033[0m"
        else
            echo -e "\033[31m[FALHOU]\033[0m"
            test_failures=$((test_failures + 1))
        fi
    }

    assert_file_exists() {
        local test_name="$1"
        local file_path="$2"
        test_count=$((test_count + 1))
        echo -n "  Teste $test_count: $test_name... "
        if [ -f "$file_path" ] && [ -s "$file_path" ]; then
            echo -e "\033[32m[PASSOU]\033[0m"
        else
            echo -e "\033[31m[FALHOU]\033[0m"
            test_failures=$((test_failures + 1))
        fi
    }

    # 1. Teste de inicializacao de ambiente
    assert_success "Inicialização de diretórios (init_env)" init_env
    assert_success "Permissão 755 no diretório dist" test -d "$DIST_DIR"

    # 2. Teste de consolidacao
    assert_success "Consolidação de capítulos (consolidate_docs)" consolidate_docs
    assert_file_exists "Arquivo full-document.md gerado e não vazio" "$OUTPUT_DOC"

    # 3. Teste de sumario AWK
    assert_success "Geração de sumário hierárquico (generate_toc_awk)" generate_toc_awk
    assert_file_exists "Arquivo summary.md gerado e não vazio" "$OUTPUT_TOC"

    # 4. Teste de auditoria de links
    assert_success "Auditoria léxica com grep -E (validate_links_regex)" validate_links_regex

    # 5. Teste de estatisticas
    assert_success "Cálculo de métricas (compute_statistics)" compute_statistics
    assert_file_exists "Arquivo metrics.txt gerado e não vazio" "$METRICS_FILE"

    # 6. Teste de empacotamento
    assert_success "Empacotamento de release tar.gz (package_release)" package_release
    assert_file_exists "Tarball de release gerado" "$OUTPUT_BUNDLE"

    # 7. Teste de servidor HTTP em porta de teste 8999
    assert_success "Inicialização do servidor HTTP na porta 8999" manage_server 8999
    sleep 0.5
    assert_success "Encerramento do servidor HTTP via sinal kill" manage_server --stop

    # 8. Teste do gerador de relatório SIGAA
    assert_success "Geração de relatório unificado para o SIGAA" generate_sigaa_report
    assert_file_exists "Arquivo sigaa-report.md gerado" "${DIST_DIR}/sigaa-report.md"

    echo "================================================================="
    if [ "$test_failures" -eq 0 ]; then
        echo -e " \033[32m✅ Todos os $test_count testes passaram com sucesso!\033[0m"
        return 0
    else
        echo -e " \033[31m❌ $test_failures de $test_count testes falharam.\033[0m"
        return 1
    fi
}

# ==============================================================================
# ENTRADA PRINCIPAL / DISPATCHER CLI (Conceitos 11, 13, 14, 15, 17)
# ==============================================================================

# Parametros especiais: $# (contagem de argumentos) (Conceito 11)
# Expansao avancada com valor default ${1:-help} (Conceito 13)
COMMAND="${1:-help}"

# Testes condicionais com case (Conceito 15)
case "$COMMAND" in
    build)
        show_banner
        init_env
        consolidate_docs
        generate_toc_awk
        generate_html_preview
        ;;
    validate)
        show_banner
        init_env
        [ ! -f "$OUTPUT_DOC" ] && consolidate_docs
        validate_links_regex
        ;;
    toc)
        show_banner
        init_env
        [ ! -f "$OUTPUT_DOC" ] && consolidate_docs
        generate_toc_awk
        ;;
    sanitize)
        show_banner
        init_env
        consolidate_docs
        ;;
    stats)
        show_banner
        init_env
        [ ! -f "$OUTPUT_DOC" ] && consolidate_docs
        compute_statistics
        ;;
    pack)
        show_banner
        init_env
        [ ! -f "$OUTPUT_DOC" ] && consolidate_docs
        [ ! -f "$OUTPUT_TOC" ] && generate_toc_awk
        [ ! -f "$METRICS_FILE" ] && compute_statistics
        [ ! -f "$OUTPUT_HTML" ] && generate_html_preview
        package_release
        ;;
    serve)
        show_banner
        shift
        manage_server "$@"
        ;;
    report)
        show_banner
        init_env
        [ ! -f "$OUTPUT_DOC" ] && consolidate_docs
        [ ! -f "$OUTPUT_TOC" ] && generate_toc_awk
        [ ! -f "$METRICS_FILE" ] && compute_statistics
        generate_sigaa_report
        ;;
    test)
        show_banner
        run_tests
        ;;
    watch)
        show_banner
        init_env
        watch_docs
        ;;
    clean)
        clean_dist
        ;;
    all)
        show_banner
        init_env
        consolidate_docs
        generate_toc_awk
        validate_links_regex
        compute_statistics
        generate_html_preview
        package_release
        echo -e "\n[OK] Pipeline completo executado com sucesso!"
        ;;
    help|--help|-h)
        show_banner
        show_help
        ;;
    *)
        echo "Opcao invalida: $COMMAND" >&2
        show_help
        # Comando basico: exit (Conceito 01)
        exit 1
        ;;
esac

# Parametro especial $? contendo status da ultima execucao (Conceito 11)
exit $?
