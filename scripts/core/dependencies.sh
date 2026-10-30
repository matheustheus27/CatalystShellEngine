#!/usr/bin/env bash
# ==============================================================================
# Catalyst Shell Engine - Gerenciamento de Dependencias do Sistema e Ferramentas
# ==============================================================================

# Verifica o status de um utilitario no PATH
_check_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Verifica se o Node.js esta disponivel (nativo ou via interoperabilidade)
_check_node() {
    _check_cmd node || _check_cmd node.exe
}

# Verifica se o netcat instalado suporta a flag -N (OpenBSD)
_check_nc_openbsd() {
    if _check_cmd nc; then
        nc -h 2>&1 | grep -q -- '-N'
    else
        return 1
    fi
}

# Verifica se o Python possui reportlab instalado
_check_reportlab() {
    local py_cmd="${CATALYST_PDF_PYTHON:-python3}"
    if _check_cmd "$py_cmd"; then
        "$py_cmd" -c "import reportlab" >/dev/null 2>&1
    elif [ -x "$BASE_DIR/.venv/bin/python3" ]; then
        "$BASE_DIR/.venv/bin/python3" -c "import reportlab" >/dev/null 2>&1
    else
        return 1
    fi
}

# Verifica se as fontes DejaVu necessarias estao instaladas
_check_dejavu_fonts() {
    local font_paths=(
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
        "/usr/share/fonts/dejavu/DejaVuSans.ttf"
        "/usr/local/share/fonts/DejaVuSans.ttf"
        "/mnt/c/Windows/Fonts/arial.ttf"
        "C:/Windows/Fonts/arial.ttf"
    )
    for f in "${font_paths[@]}"; do
        if [ -f "$f" ]; then return 0; fi
    done
    return 1
}

# Verifica se o Chromium para Playwright esta instalado
_check_playwright_chromium() {
    local pw_paths=(
        "$HOME/.cache/ms-playwright/chromium_headless_shell-"*
        "$LOCALAPPDATA/ms-playwright/chromium_headless_shell-"*
        "/home/runner/.cache/ms-playwright/chromium_headless_shell-"*
    )
    for p in "${pw_paths[@]}"; do
        if compgen -G "$p" >/dev/null; then return 0; fi
    done
    return 1
}

# Formata o status para exibicao colorida no terminal
_dep_status() {
    local ok="$1"
    if [ "$ok" = 0 ]; then
        printf "\033[32m[INSTALADO]\033[0m"
    else
        printf "\033[31m[ AUSENTE ]\033[0m"
    fi
}

list_dependencies() {
    echo "================================================================="
    echo " Verificacao de Dependencias - Catalyst Shell Engine"
    echo "================================================================="
    printf "%-18s %-22s %-12s %s\n" "COMPONENTE" "PACOTE SUGERIDO" "STATUS" "FINALIDADE"
    echo "-----------------------------------------------------------------"

    local -i total=0 installed=0

    _row() {
        local name="$1" pkg="$2" desc="$3"
        shift 3
        local ok=1
        if "$@"; then ok=0; fi
        total+=1
        if [ "$ok" = 0 ]; then installed+=1; fi
        printf "%-18s %-22s %b  %s\n" "$name" "$pkg" "$(_dep_status "$ok")" "$desc"
    }

    # 1. Nucleo Bash e processamento de texto
    _row "Bash (>=4.4)" "bash" "Interpretador shell do motor" _check_cmd bash
    _row "GNU AWK (gawk)" "gawk" "Compilador markdown e gerador de sumario" _check_cmd gawk
    _row "sed" "sed" "Normalizacao CRLF e transformacoes de texto" _check_cmd sed
    _row "grep (GNU)" "grep" "Validacao por regex de links e arquivos" _check_cmd grep
    _row "findutils" "findutils" "Localizacao de capitulos e calculo de checksums" _check_cmd find
    _row "tar (GNU)" "tar" "Empacotamento deterministico do release" _check_cmd tar
    _row "gzip" "gzip" "Compressao do arquivo .tar.gz sem timestamp" _check_cmd gzip
    _row "util-linux" "util-linux" "Bloqueio atomico (flock) e daemons (setsid)" _check_cmd flock

    # 2. Servidores de Preview
    _row "OpenBSD netcat" "netcat-openbsd" "Servidor HTTP local do backend Bash (-N)" _check_nc_openbsd
    _row "Python 3" "python3" "Servidor concorrente e scripts auxiliares" _check_cmd python3

    # 3. Relatorio e Exportacao PDF
    _row "cloc" "cloc" "Contagem oficial de linhas do relatorio SIGAA" _check_cmd cloc
    _row "reportlab" "python3-reportlab" "Exportador do relatorio em PDF (A4 paisagem)" _check_reportlab
    _row "DejaVu Fonts" "fonts-dejavu-core" "Tipografia TrueType do relatorio PDF" _check_dejavu_fonts

    # 4. Qualidade e Testes de Interface
    _row "ShellCheck" "shellcheck" "Linter estatico de conformidade shell" _check_cmd shellcheck
    _row "Node.js (>=24)" "nodejs" "Execucao dos testes de interface web" _check_node
    _row "npm" "npm" "Gerenciador de pacotes para jsdom e Playwright" _check_cmd npm
    _row "Chromium (Playwright)" "npx playwright" "Testes reais de navegacao, layout e impressao" _check_playwright_chromium

    echo "-----------------------------------------------------------------"
    printf "Resumo: %d/%d dependencias disponiveis no ambiente atual.\n" "$installed" "$total"
    if [ "$installed" -lt "$total" ]; then
        echo ""
        echo "Dica: Execute './catalyst.sh dependencies --install' para instalar"
        echo "      automaticamente os pacotes de sistema e dependencias faltantes."
    fi
}

install_dependencies() {
    echo "================================================================="
    echo " Instalador de Dependencias - Catalyst Shell Engine"
    echo "================================================================="

    # Detecta privilegios e capacidade de sudo
    local pm="" sudo_cmd="" can_sudo=0
    if [ "$(id -u)" -eq 0 ]; then
        can_sudo=1
    elif _check_cmd sudo; then
        if sudo -n true 2>/dev/null; then
            sudo_cmd="sudo"
            can_sudo=1
        elif [ -t 0 ]; then
            sudo_cmd="sudo"
            can_sudo=1
        else
            can_sudo=0
        fi
    fi

    if _check_cmd apt-get; then
        pm="apt"
    elif _check_cmd pacman; then
        pm="pacman"
    elif _check_cmd dnf; then
        pm="dnf"
    elif _check_cmd brew; then
        pm="brew"
    fi

    if [ "$pm" = "apt" ]; then
        echo "[1/3] Identificando pacotes ausentes via apt-get..."
        local -a missing_pkgs=()

        _check_cmd gawk || missing_pkgs+=(gawk)
        _check_cmd sed || missing_pkgs+=(sed)
        _check_cmd grep || missing_pkgs+=(grep)
        _check_cmd find || missing_pkgs+=(findutils)
        _check_cmd tar || missing_pkgs+=(tar)
        _check_cmd gzip || missing_pkgs+=(gzip)
        _check_cmd flock || missing_pkgs+=(util-linux)
        _check_nc_openbsd || missing_pkgs+=(netcat-openbsd)
        _check_cmd python3 || missing_pkgs+=(python3)
        _check_cmd cloc || missing_pkgs+=(cloc)
        _check_cmd shellcheck || missing_pkgs+=(shellcheck)
        _check_reportlab || missing_pkgs+=(python3-reportlab)
        _check_dejavu_fonts || missing_pkgs+=(fonts-dejavu-core)

        if [ "${#missing_pkgs[@]}" -gt 0 ]; then
            if [ "$can_sudo" = 1 ]; then
                echo "Instalando pacotes do sistema: ${missing_pkgs[*]}..."
                $sudo_cmd apt-get update
                $sudo_cmd apt-get install -y "${missing_pkgs[@]}"
            else
                echo "Os seguintes pacotes de sistema estao ausentes: ${missing_pkgs[*]}"
                echo "Aviso: sudo requer autenticacao e a sessao atual e nao-interativa."
                echo "Execute no terminal: sudo apt-get update && sudo apt-get install -y ${missing_pkgs[*]}"
            fi
        else
            echo "Todos os pacotes de sistema essenciais estao instalados."
        fi
    elif [ -n "$pm" ]; then
        echo "Gerenciador detectado: $pm. Instale os equivalentes a: gawk, netcat-openbsd, cloc, shellcheck, python3-reportlab, fonts-dejavu-core."
    else
        echo "Gerenciador de pacotes de sistema nao identificado automaticamente."
    fi

    # 2. Dependencias Python (fallback para venv se reportlab ainda faltar)
    echo "[2/3] Verificando ambiente Python e ReportLab..."
    if ! _check_reportlab; then
        echo "Criando ambiente virtual Python local em .venv..."
        if _check_cmd python3; then
            python3 -m venv "$BASE_DIR/.venv" 2>/dev/null || {
                $sudo_cmd apt-get install -y python3-venv 2>/dev/null || true
                python3 -m venv "$BASE_DIR/.venv"
            }
            if [ -x "$BASE_DIR/.venv/bin/pip" ]; then
                "$BASE_DIR/.venv/bin/pip" install --upgrade pip reportlab
                echo "ReportLab instalado com sucesso em $BASE_DIR/.venv."
            fi
        fi
    else
        echo "Biblioteca ReportLab pronta para geracao de PDF."
    fi

    # 3. Dependencias Node.js e Playwright
    echo "[3/3] Verificando dependencias npm e Playwright..."
    if _check_cmd npm; then
        if [ -f "$BASE_DIR/package.json" ]; then
            echo "Instalando dependencias de desenvolvimento do npm..."
            (cd "$BASE_DIR" && npm install --no-audit --no-fund)
        fi
        if ! _check_playwright_chromium; then
            echo "Instalando navegador Chromium para Playwright..."
            if _check_cmd npx; then
                if ! (cd "$BASE_DIR" && npx playwright install --with-deps --only-shell chromium 2>/dev/null); then
                    (cd "$BASE_DIR" && npx playwright install --only-shell chromium)
                fi
            fi
        fi
    else
        echo "Aviso: 'npm' nao encontrado. Para testes de interface com Chromium real, instale Node.js e npm."
    fi

    echo ""
    echo "Instalacao concluida. Verificando status atualizado:"
    echo ""
    list_dependencies
}

manage_dependencies() {
    local action="${1:---list}"
    case "$action" in
        --install|-i|install)
            install_dependencies
            ;;
        --list|-l|list|--check|check|"")
            list_dependencies
            ;;
        --help|-h|help)
            echo "Uso: ./catalyst.sh dependencies [--list | --install]"
            echo ""
            echo "Opcoes:"
            echo "  --list, -l      Verifica e lista o status de cada dependencia do sistema"
            echo "  --install, -i   Instala automaticamente os pacotes ausentes (apt, reportlab, Playwright)"
            echo "  --help, -h      Exibe esta mensagem de ajuda"
            ;;
        *)
            echo "Opcao desconhecida para dependencies: $action" >&2
            echo "Use: ./catalyst.sh dependencies [--list | --install]" >&2
            return 1
            ;;
    esac
}
