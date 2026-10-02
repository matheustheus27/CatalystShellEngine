#!/usr/bin/env bash

# ==============================================================================
# Catalyst Shell Engine - Preview HTTP Server Lifecycle
# ==============================================================================
# Este modulo controla o ciclo de vida do servidor de preview.
#
# A comunicacao HTTP e realizada utilizando recursos do Bash e o utilitario
# de sistema nc (netcat), eliminando a dependencia de Python.
# ==============================================================================

set -e

# Arquivos externos utilizados para armazenar o PID e a porta do servidor.
# Conceito 03: manipulacao de arquivos do sistema.
PID_FILE="/tmp/catalyst_server.pid"
PORT_FILE="/tmp/catalyst_server.port"

start_server() {
    local serve_dir="$1"
    local port="$2"

    # Se a porta nao for fornecida explicitamente, tenta reaproveitar a porta
    # registrada na execucao anterior antes de recorrer ao valor padrao 8000.
    # Conceito 13: expansao avancada com fallback ${port:-8000}.
    if [ -z "$port" ] && [ -f "$PORT_FILE" ]; then
        port=$(cat "$PORT_FILE" 2>/dev/null || true)
    fi
    port="${port:-8000}"

    # Parametros posicionais (Conceito 11):
    # $1 representa o diretorio disponibilizado pelo servidor.
    # $2 representa a porta recebida pelo modulo.

    # Verifica se o diretorio informado existe.
    # Conceito 14: teste condicional com expressao de arquivo.
    if [ ! -d "$serve_dir" ]; then
        echo "Diretorio nao encontrado: $serve_dir" >&2
        return 1
    fi

    # Verifica se existe um arquivo PID de uma execucao anterior.
    # Conceito 14: teste condicional com expressao de arquivo.
    if [ -f "$PID_FILE" ]; then
        local old_pid

        # Leitura do arquivo utilizando substituicao de comandos.
        # Conceito 09: substituicao de comandos $(...).
        old_pid=$(cat "$PID_FILE" 2>/dev/null || true)

        # Inspeciona se o processo armazenado no PID ainda existe.
        # Conceito 05: gerenciamento e consulta de processos com ps.
        if [ -n "$old_pid" ] && ps -p "$old_pid" >/dev/null 2>&1; then
            echo "Servidor ja esta em execucao com PID $old_pid."
            return 0
        fi

        # Remove arquivo PID e arquivo de porta residuais.
        rm -f "$PID_FILE" "$PORT_FILE"
    fi

    # Verifica se o utilitario de sistema nc (netcat) esta disponivel.
    # O projeto utiliza Bash + ferramentas do sistema, sem Python.
    #
    # Conceito 14: teste condicional.
    # Conceito 16: operador logico de negacao.
    if ! command -v nc >/dev/null 2>&1; then
        echo "Erro: nc (netcat) nao encontrado no sistema." >&2
        return 1
    fi

    echo "Iniciando servidor na porta $port..."

    # Agrupa os comandos em um subshell para manter o diretorio de trabalho
    # isolado do shell principal.
    #
    # Conceito 11: processo executado em background com $!.
    (
        cd "$serve_dir" || exit 1

        local req_tmp="/tmp/catalyst_req_$$.tmp"
        local res_tmp="/tmp/catalyst_res_$$.tmp"
        local fifo="/tmp/catalyst_fifo_$$"

        rm -f "$req_tmp" "$res_tmp" "$fifo"
        mkfifo "$fifo"

        trap 'rm -f "$req_tmp" "$res_tmp" "$fifo"' EXIT INT TERM

        while true; do
            # Limpa temporarios
            > "$req_tmp"
            > "$res_tmp"

            # 1. Aguarda requisicao e captura a primeira linha (ou cabecalho)
            # O netcat envia a conexao para o parser via FIFO bidirecional
            cat "$fifo" | nc -l "$port" | (
                # Le a primeira linha (GET /path HTTP/1.1)
                IFS= read -r request || true
                echo "$request" > "$req_tmp"

                # Drena o restante dos cabecalhos para desocupar o buffer TCP
                while IFS= read -r line; do
                    line=$(printf '%s' "$line" | tr -d '\r')
                    [ -z "$line" ] && break
                done

                # Extrai o caminho solicitado
                request=$(cat "$req_tmp" | tr -d '\r')
                requested_path="${request#GET }"
                requested_path="${requested_path%% HTTP/*}"
                requested_path="${requested_path%%\?*}"

                if [ -z "$requested_path" ] || [ "$requested_path" = "/" ]; then
                    requested_path="/index.html"
                fi

                requested_file="${requested_path#/}"

                # 2. Monta a resposta completa
                if [[ "$requested_file" == *".."* ]]; then
                    {
                        printf "HTTP/1.1 403 Forbidden\r\n"
                        printf "Content-Type: text/plain; charset=utf-8\r\n"
                        printf "Connection: close\r\n\r\n"
                        printf "403 - Acesso negado\n"
                    } > "$fifo"

                elif [ -f "$requested_file" ]; then
                    file_size=$(wc -c < "$requested_file")
                    content_type="application/octet-stream"

                    case "$requested_file" in
                        *.html) content_type="text/html; charset=utf-8" ;;
                        *.css)  content_type="text/css; charset=utf-8" ;;
                        *.js)   content_type="application/javascript; charset=utf-8" ;;
                        *.json) content_type="application/json; charset=utf-8" ;;
                        *.md)   content_type="text/markdown; charset=utf-8" ;;
                        *.txt)  content_type="text/plain; charset=utf-8" ;;
                        *.svg)  content_type="image/svg+xml" ;;
                        *.png)  content_type="image/png" ;;
                        *.ico)  content_type="image/x-icon" ;;
                    esac

                    {
                        printf "HTTP/1.1 200 OK\r\n"
                        printf "Content-Type: %s\r\n" "$content_type"
                        printf "Content-Length: %s\r\n" "$file_size"
                        printf "Connection: close\r\n\r\n"
                        cat "$requested_file"
                    } > "$fifo"

                else
                    {
                        printf "HTTP/1.1 404 Not Found\r\n"
                        printf "Content-Type: text/plain; charset=utf-8\r\n"
                        printf "Connection: close\r\n\r\n"
                        printf "404 - Arquivo nao encontrado: %s\n" "$requested_file"
                    } > "$fifo"
                fi
            )

            # Evita colisao na reciclagem do bind da porta no kernel
            sleep 0.05
        done
    ) >/dev/null 2>&1 &

    # Parametro especial $! (Conceito 11):
    # contem o PID do ultimo processo executado em background.
    local server_pid=$!

    # Redireciona o PID e a porta para arquivos externos.
    # Conceito 07: redirecionamento de saida.
    echo "$server_pid" > "$PID_FILE"
    echo "$port" > "$PORT_FILE"

    echo "Servidor iniciado."
    echo "PID: $server_pid"
    echo "URL: http://localhost:$port"
}

restart_server() {
    local serve_dir="$1"
    local requested_port="$2"

    # 1. Recupera o valor da porta em ficheiro caso nao tenha sido passado
    if [ -z "$requested_port" ] && [ -f "$PORT_FILE" ]; then
        requested_port=$(cat "$PORT_FILE" 2>/dev/null || true)
    fi

    # 2. Garante o fallback para 8000 se o ficheiro nao existir
    requested_port="${requested_port:-8000}"

    # 3. Encerra o processo (que limpa os ficheiros temporarios)
    stop_server
    sleep 0.5

    # 4. Inicia novamente com a porta preservada
    start_server "$serve_dir" "$requested_port"
}

stop_server() {
    # Verifica se existe um registro de servidor.
    # Conceito 14: teste condicional com expressao de arquivo.
    if [ ! -f "$PID_FILE" ]; then
        echo "Nenhum servidor registrado."
        rm -f "$PORT_FILE"
        return 0
    fi

    # Recupera o PID armazenado.
    # Conceito 09: substituicao de comandos.
    local target_pid
    target_pid=$(cat "$PID_FILE")

    # Inspeciona o processo usando ps.
    # Conceito 05: gerenciamento de processos.
    #
    # Conceito 07: redirecionamento da saida padrao e da saida de erro.
    if ps -p "$target_pid" >/dev/null 2>&1; then
        echo "Encerrando servidor PID $target_pid..."

        # Envia SIGTERM para solicitar o encerramento do processo.
        # Conceito 06: sinais de processos utilizando kill.
        #
        # Conceito 16: operador || para executar uma segunda alternativa
        # caso o primeiro comando falhe.
        kill -15 "$target_pid" 2>/dev/null || \
            kill -9 "$target_pid" 2>/dev/null
    else
        echo "Processo $target_pid nao esta ativo."
    fi

    # Remove os arquivos de estado.
    rm -f "$PID_FILE" "$PORT_FILE"
}

# ==============================================================================
# Interface de linha de comando do modulo
# ==============================================================================

# Seleciona a operacao solicitada pelo shell principal.
# Conceito 15: estrutura condicional case.
case "$1" in
    start)
        # Parametros posicionais:
        # $1 = start
        # $2 = diretorio
        # $3 = porta
        #
        # Conceito 11: parametros posicionais.
        start_server "$2" "$3"
        ;;

    restart)
        restart_server "$2" "$3"
        ;;

    stop)
        stop_server
        ;;

    *)
        # Redirecionamento para stderr.
        # Conceito 07: saida de erro padrao.
        echo "Uso: $0 {start|restart|stop} [diretorio] [porta]" >&2
        exit 1
        ;;
esac