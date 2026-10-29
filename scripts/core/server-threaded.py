#!/usr/bin/env python3
"""Preview concorrente opcional: apenas biblioteca padrao, bind local e flock."""
from contextlib import contextmanager
import fcntl
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import mimetypes
from pathlib import Path
import shutil
import subprocess
import sys
import threading
from urllib.parse import unquote, urlsplit


class Preview(ThreadingHTTPServer):
    daemon_threads = True
    request_queue_size = 64

    def __init__(self, *args):
        self.slots = threading.BoundedSemaphore(32)
        super().__init__(*args)

    def process_request(self, request, address):
        self.slots.acquire()
        try:
            super().process_request(request, address)
        except Exception:
            self.slots.release()
            raise

    def process_request_thread(self, request, address):
        try:
            super().process_request_thread(request, address)
        finally:
            self.slots.release()


def run(directory: str, state: str, port: int, lifecycle: str):
    published, state_dir = Path(directory), Path(state)
    policy = (Path(lifecycle).parent.parent.parent / 'templates/csp.txt').read_text().strip()

    @contextmanager
    def snapshot():
        with (state_dir / 'publish.lock').open('a') as lock:
            fcntl.flock(lock, fcntl.LOCK_SH)
            if (state_dir / 'in-progress').exists() or (not published.exists() and (state_dir / 'previous').exists()):
                fcntl.flock(lock, fcntl.LOCK_EX)
                subprocess.run(['bash', str(Path(lifecycle).with_name('transaction.sh')),
                                'recover', str(published), str(state_dir)], check=True)
                fcntl.flock(lock, fcntl.LOCK_SH)
            yield published.resolve()

    class Handler(BaseHTTPRequestHandler):
        protocol_version = 'HTTP/1.1'

        def setup(self):
            super().setup()
            self.connection.settimeout(8)

        def headers(self, code, size, mime):
            self.send_response(code)
            self.send_header('Content-Type', mime)
            self.send_header('Content-Length', str(size))
            self.send_header('Cache-Control', 'no-cache')
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.send_header('Referrer-Policy', 'no-referrer')
            self.send_header('Content-Security-Policy', policy)
            self.end_headers()

        def fail(self, code, message):
            body = message.encode()
            self.headers(code, len(body), 'text/plain; charset=utf-8')
            if self.command != 'HEAD':
                self.wfile.write(body)

        def do_GET(self):
            parsed = urlsplit(self.path)
            try:
                target = unquote(parsed.path, errors='strict')
            except (UnicodeError, ValueError):
                return self.fail(400, 'URL invalida')
            if parsed.scheme or parsed.netloc or any(c in target for c in ('\0', '\r', '\n', '\\')):
                return self.fail(400, 'URL invalida')
            with snapshot() as root:
                file = (root / (target.lstrip('/') or 'index.html')).resolve()
                if not file.is_relative_to(root):
                    return self.fail(403, 'Acesso negado')
                if not file.is_file():
                    return self.fail(404, 'Arquivo nao encontrado')
                mime = mimetypes.guess_type(file)[0] or 'application/octet-stream'
                if file.suffix in ('.js', '.mjs'):
                    mime = 'application/javascript'
                with file.open('rb') as stream:
                    self.headers(200, file.stat().st_size, mime)
                    if self.command != 'HEAD':
                        shutil.copyfileobj(stream, self.wfile)

        def do_HEAD(self):
            return self.do_GET()

        def do_POST(self):
            self.close_connection = True
            return self.fail(405, 'Metodo nao permitido')

        do_PUT = do_POST
        do_DELETE = do_POST
        do_OPTIONS = do_POST

    with Preview(('127.0.0.1', port), Handler) as server:
        server.serve_forever(poll_interval=0.1)


if __name__ == '__main__':
    run(sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4])
