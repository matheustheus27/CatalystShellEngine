#!/usr/bin/env bash
# Preview HTTP local: Bash + OpenBSD netcat. Nao recebe entrada do teclado.
set -eo pipefail
SCRIPT="$(realpath "$0")"
# shellcheck source=scripts/core/transaction.sh
source "$(dirname "$SCRIPT")/transaction.sh"
ACTION="${1:-}"
SERVE_DIR="$(realpath -ms "${2:-.}")"
PUBLISH_STATE="$(dirname "$SERVE_DIR")/.catalyst"
mkdir -p "$PUBLISH_STATE"
PORT="${3:-}"
BACKEND="${4:-}"
POLICY="$(<"$(dirname "$SCRIPT")/../../templates/csp.txt")"
# Estado privado por usuario e projeto.
STATE="${TMPDIR:-/tmp}/catalyst-${UID}-$(printf '%s' "$SERVE_DIR" | sha256sum | cut -c1-16)"
umask 077
mkdir -p "$STATE"
chmod 700 "$STATE"

is_our_server() {
    local pid="$1"
    [[ "$pid" =~ ^[0-9]+$ ]] || return 1
    ps -p "$pid" >/dev/null 2>&1 || return 1
    local -a args=()
    [ -r "/proc/$pid/cmdline" ] || return 1
    mapfile -d '' -t args < "/proc/$pid/cmdline"
    [[ "${args[1]:-}" == "$SCRIPT" && "${args[2]:-}" == worker && "${args[3]:-}" == "$SERVE_DIR" ]]
}

respond() (
    local request method target version line file status body type root
    IFS= read -r request || return 0
    request="${request%$'\r'}"
    read -r method target version <<< "$request"
    while IFS= read -r line; do [ "${line%$'\r'}" ] || break; done
    exec 8>"$PUBLISH_STATE/publish.lock"
    flock -s 8
    if [ -f "$PUBLISH_STATE/in-progress" ] || { [ ! -e "$SERVE_DIR" ] && [ -d "$PUBLISH_STATE/previous" ]; }; then
        flock -x 8
        recover_publication "$SERVE_DIR" "$PUBLISH_STATE"
        flock -s 8
    fi
    root=$(realpath -m "$SERVE_DIR")
    target="${target%%\?*}"
    [ "$target" != / ] || target=/index.html
    local decoded="" prefix hex char encoded="$target" invalid=0
    while [[ "$encoded" == *%* ]]; do
        prefix="${encoded%%\%*}"; encoded="${encoded#*%}"; hex="${encoded:0:2}"
        if [[ ! "$hex" =~ ^[0-9a-fA-F]{2}$ || "$hex" = 00 ]]; then invalid=1; break; fi
        printf -v char '%b' "\\x$hex"
        decoded+="$prefix$char"; encoded="${encoded:2}"
    done
    target="$decoded$encoded"
    file="$(realpath -m "$root/${target#/}")"
    status='200 OK'; type='application/octet-stream'; body=''
    if [ "$invalid" = 1 ] || [[ "$target" == *$'\r'* || "$target" == *$'\n'* ]]; then
        status='400 Bad Request'; body='URL invalida'
    elif [[ "$version" != HTTP/1.0 && "$version" != HTTP/1.1 ]]; then
        status='400 Bad Request'; body='Requisicao invalida'
    elif [ "$method" != GET ] && [ "$method" != HEAD ]; then
        status='405 Method Not Allowed'; body='Metodo nao permitido'
    elif [[ "$target" != /* || "$target" == *\\* || "$file" != "$root/"* ]]; then
        status='403 Forbidden'; body='Acesso negado'
    elif [ ! -f "$file" ] || [ ! -r "$file" ]; then
        status='404 Not Found'; body='Arquivo nao encontrado'
    else
        case "$file" in
            *.html) type='text/html; charset=utf-8' ;;
            *.css) type='text/css; charset=utf-8' ;;
            *.js|*.mjs) type='application/javascript; charset=utf-8' ;;
            *.json) type='application/json; charset=utf-8' ;;
            *.md|*.txt) type='text/plain; charset=utf-8' ;;
            *.svg) type='image/svg+xml' ;;
            *.png) type='image/png' ;;
        esac
    fi
    local size response_policy="$POLICY"
    if [[ "$file" == "$root/assets/"* ]]; then
        response_policy="sandbox; default-src 'none'; style-src 'unsafe-inline'; img-src data:"
    fi
    if [ "$status" = '200 OK' ]; then size=$(wc -c < "$file"); else
        type='text/plain; charset=utf-8'; size=${#body}
    fi
    printf 'HTTP/1.1 %s\r\nContent-Type: %s\r\nContent-Length: %s\r\nConnection: close\r\nX-Content-Type-Options: nosniff\r\nReferrer-Policy: no-referrer\r\nContent-Security-Policy: %s\r\n\r\n' "$status" "$type" "$size" "$response_policy"
    if [ "$method" != HEAD ]; then
        if [ "$status" = '200 OK' ]; then cat "$file"; else printf '%s' "$body"; fi
    fi
)

worker() {
    if [ "$BACKEND" = threaded ]; then
        trap 'exit 0' INT TERM
        python3 "$(dirname "$SCRIPT")/server-threaded.py" "$SERVE_DIR" "$PUBLISH_STATE" "$PORT" "$SCRIPT" &
        wait "$!"
        return
    fi
    local fifo="$STATE/response"
    rm -f "$fifo"
    mkfifo "$fifo"
    trap 'rm -f "$fifo"' EXIT
    trap 'exit 0' INT TERM
    while true; do
        # EOF fecha a conexao; timeout limita clientes com cabecalhos incompletos.
        # FIFO bidirecional intencional: resposta HTTP alimenta o stdin do nc.
        # shellcheck disable=SC2094
        if ! timeout --foreground 10 nc -N -l 127.0.0.1 "$PORT" < "$fifo" | respond > "$fifo"; then
            sleep 0.1
        fi
    done
}

stop_server() {
    local pid
    if [ -f "$STATE/pid" ]; then
        pid=$(cat "$STATE/pid")
        if is_our_server "$pid"; then
            # Sessao propria permite encerrar tambem nc e parsers filhos.
            kill -15 -- "-$pid" 2>/dev/null || true
            for _ in {1..30}; do
                is_our_server "$pid" || break
                sleep 0.1
            done
            if is_our_server "$pid"; then kill -9 -- "-$pid" 2>/dev/null || true; fi
        fi
    fi
    rm -f "$STATE/pid" "$STATE/port" "$STATE/backend" "$STATE/response"
    echo 'Servidor encerrado.'
}

start_server() {
    [ -d "$SERVE_DIR" ] || { echo 'Execute build antes de serve.' >&2; return 1; }
    PORT="${PORT:-8000}"
    BACKEND="${BACKEND:-bash}"
    [[ "$BACKEND" = bash || "$BACKEND" = threaded ]] || { echo 'Backend invalido: bash ou threaded.' >&2; return 1; }
    if [ "$BACKEND" = threaded ]; then
        command -v python3 >/dev/null || { echo 'O backend threaded exige python3.' >&2; return 1; }
    fi
    if [[ ! "$PORT" =~ ^[0-9]{1,5}$ ]] || ((10#$PORT < 1 || 10#$PORT > 65535)); then
        echo 'Porta invalida: use um inteiro de 1 a 65535.' >&2
        return 1
    fi
    PORT=$((10#$PORT))
    for utility in nc setsid flock realpath sha256sum timeout; do
        command -v "$utility" >/dev/null || { echo "Dependencia ausente: $utility" >&2; return 1; }
    done
    if ! nc -h 2>&1 | grep -q -- '-N'; then
        echo 'O preview exige OpenBSD netcat com a opcao -N.' >&2; return 1
    fi
    if [ -f "$STATE/pid" ] && is_our_server "$(cat "$STATE/pid")"; then
        if [ "$(cat "$STATE/port")" != "$PORT" ] || [ "$(cat "$STATE/backend")" != "$BACKEND" ]; then
            echo 'Servidor ativo em outra porta; use serve --restart --port PORTA.' >&2; return 1
        fi
        echo "Servidor ja ativo em http://127.0.0.1:$PORT"; return 0
    fi
    if nc -z -w 1 127.0.0.1 "$PORT"; then
        echo "Porta $PORT ocupada." >&2; return 1
    fi
    setsid bash "$SCRIPT" worker "$SERVE_DIR" "$PORT" "$BACKEND" 9>&- >"$STATE/server.log" 2>&1 < /dev/null &
    local server_pid=$!
    echo "$server_pid" > "$STATE/pid"
    echo "$PORT" > "$STATE/port"
    echo "$BACKEND" > "$STATE/backend"
    for _ in {1..40}; do
        if is_our_server "$server_pid" && nc -z -w 1 127.0.0.1 "$PORT"; then
            echo "Servidor iniciado: http://127.0.0.1:$PORT (backend $BACKEND, PID $server_pid)"; return 0
        fi
        sleep 0.1
    done
    stop_server
    echo "Falha ao iniciar servidor. Consulte $STATE/server.log" >&2
    return 1
}

if [ "$ACTION" = worker ]; then worker; exit; fi
exec 9>"$STATE/lock"
flock -x 9
case "$ACTION" in
    start) start_server ;;
    stop) stop_server ;;
    restart)
        [ -n "$PORT" ] || PORT=$(cat "$STATE/port" 2>/dev/null || printf 8000)
        [ -n "$BACKEND" ] || BACKEND=$(cat "$STATE/backend" 2>/dev/null || printf bash)
        stop_server
        start_server
        ;;
    *) echo "Uso: $0 {start|stop|restart} DIRETORIO [PORTA]" >&2; exit 1 ;;
esac
