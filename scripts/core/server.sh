#!/usr/bin/env bash
# ==============================================================================
# Catalyst Shell Engine - Preview HTTP Server Lifecycle (ps, jobs, kill)
# ==============================================================================
set -e

PID_FILE="/tmp/catalyst_server.pid"

start_preview_server() {
    local serve_dir="$1"
    local port="${2:-8000}"

    if [ -f "$PID_FILE" ]; then
        local old_pid
        old_pid=$(cat "$PID_FILE" 2>/dev/null || true)
        # Inspeciona se processo existe usando ps (Conceito 05)
        if [ -n "$old_pid" ] && ps -p "$old_pid" >/dev/null 2>&1; then
            echo "Servidor de preview ja esta em execucao com PID $old_pid na porta $port."
            return 0
        fi
    fi

    echo "Iniciando servidor de documentacao na porta $port..."
    # Executa servidor web leve em background com redirecionamento (Conceitos 07 e 11)
    if command -v python3 &>/dev/null; then
        (cd "$serve_dir" && python3 -m http.server "$port" >/dev/null 2>&1) &
    elif command -v python &>/dev/null; then
        (cd "$serve_dir" && python -m http.server "$port" >/dev/null 2>&1) &
    else
        echo "Nenhum interpretador compativel encontrado para subir o servidor local." >&2
        return 1
    fi

    # Parametro especial $! contendo o PID do ultimo processo em background (Conceito 11)
    local server_pid=$!
    echo "$server_pid" > "$PID_FILE"
    echo "Servidor iniciado com sucesso! PID: $server_pid (URL: http://localhost:$port)"
}

stop_preview_server() {
    if [ ! -f "$PID_FILE" ]; then
        echo "Nenhum servidor em execucao registrado em $PID_FILE."
        return 0
    fi

    local target_pid
    target_pid=$(cat "$PID_FILE")

    # Inspeciona processo com ps (Conceito 05)
    if ps -p "$target_pid" >/dev/null 2>&1; then
        echo "Enviando sinal de termino (SIGTERM) para o processo $target_pid..."
        # Sinal kill (Conceito 06)
        kill -15 "$target_pid" 2>/dev/null || kill -9 "$target_pid" 2>/dev/null
        rm -f "$PID_FILE"
        echo "Servidor de preview encerrado com sucesso."
    else
        echo "Processo $target_pid nao esta ativo. Removendo arquivo de PID residual."
        rm -f "$PID_FILE"
    fi
}
