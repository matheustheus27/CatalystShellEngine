#!/usr/bin/env bash
# ==============================================================================
# Catalyst Shell Engine - Logger & Output Utilities
# ==============================================================================

# Atributos de variaveis: readonly (Conceito 12)
readonly COLOR_RESET="\033[0m"
readonly COLOR_BOLD="\033[1m"
readonly COLOR_RED="\033[31m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_BLUE="\033[34m"
readonly COLOR_CYAN="\033[36m"
readonly COLOR_MAGENTA="\033[35m"

# Atributos de variaveis: funcao (Conceito 12)
log_header() {
    local title="$1"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}=================================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_MAGENTA} ⚛️  Catalyst Shell Engine | ${title}${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}=================================================================${COLOR_RESET}"
}

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

log_success() {
    echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $*"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[AVISO]${COLOR_RESET} $*"
}

log_error() {
    echo -e "${COLOR_RED}[ERRO]${COLOR_RESET} $*" >&2
}

log_step() {
    local current="$1"
    local total="$2"
    local message="$3"
    echo -e "\n${COLOR_BOLD}${COLOR_CYAN}[${current}/${total}]${COLOR_RESET} ${COLOR_BOLD}${message}${COLOR_RESET}"
}
