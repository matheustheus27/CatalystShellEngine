#!/usr/bin/env python3
"""Verifica os dois backends e progresso concorrente diante de cliente lento."""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import http.client
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def main():
    with tempfile.TemporaryDirectory(prefix='catalyst-http-') as temporary:
        fixture = Path(temporary)
        shutil.copy2(ROOT / 'catalyst.sh', fixture)
        for directory in ['scripts', 'templates', 'vendor', 'images']:
            shutil.copytree(ROOT / directory, fixture / directory)
        (fixture / 'docs').mkdir()
        (fixture / 'docs/01.md').write_text('# Concurrent preview\n[Download](../images/a%20b.txt)\n')
        payload = b'concurrent-content\n' * 16000
        (fixture / 'images/a b.txt').write_bytes(payload)

        def cli(*args):
            result = subprocess.run(['bash', str(fixture / 'catalyst.sh'), *args], capture_output=True, text=True, timeout=90)
            if result.returncode:
                raise AssertionError(result.stdout + result.stderr)

        cli('all')
        for backend in ['bash', 'threaded']:
            with socket.socket() as probe:
                probe.bind(('127.0.0.1', 0))
                port = probe.getsockname()[1]
            cli('serve', '--backend', backend, '--port', str(port))

            def get(url, method='GET'):
                # O backend Bash e sequencial; rearmar o listener pode exigir retry.
                import time
                for attempt in range(30):
                    connection = http.client.HTTPConnection('127.0.0.1', port, timeout=3)
                    try:
                        connection.request(method, url)
                        response = connection.getresponse()
                        body = response.read()
                        return response.status, dict(response.getheaders()), body
                    except ConnectionRefusedError:
                        if attempt == 29:
                            raise
                        time.sleep(0.05)
                    finally:
                        connection.close()

            try:
                status, headers, body = get('/')
                assert status == 200 and b'ui/app.js' in body
                assert 'script-src' in headers['Content-Security-Policy']
                assert headers['X-Content-Type-Options'] == 'nosniff'
                assert get('/ui/app.js', 'HEAD')[2] == b''
                assert get('/%2e%2e/catalyst.sh')[0] == 403
                assert get('/missing')[0] == 404
                assert get('/', 'POST')[0] == 405
                asset = get('/assets/files/images/a%20b.txt')
                assert asset[2] == payload
                assert 'sandbox' in asset[1]['Content-Security-Policy']
                assert get('/invalid%zz')[0] == 400
                if backend == 'threaded':
                    slow = socket.create_connection(('127.0.0.1', port))
                    try:
                        slow.sendall(b'GET / HTTP/1.1\r\nHost: localhost\r\nX-Slow: ')
                        with ThreadPoolExecutor(max_workers=16) as pool:
                            results = list(pool.map(lambda _: get('/assets/files/images/a%20b.txt'), range(32)))
                        expected = hashlib.sha256(payload).digest()
                        assert all(status == 200 and hashlib.sha256(body).digest() == expected for status, _, body in results)
                    finally:
                        slow.close()
                    (fixture / 'docs/01.md').write_text('# New generation\n')
                    cli('build')
                    assert b'New generation' in get('/docs/full-document.md')[2]
                cli('serve', '--restart')
                assert get('/')[0] == 200
            finally:
                cli('serve', '--stop')
            with socket.socket() as probe:
                assert probe.connect_ex(('127.0.0.1', port)) != 0
            print(f'HTTP {backend}: URLs, CSP, conteudo, restart e stop aprovados.')
        print('Concorrencia: 32 downloads integros com cliente lento conectado; nova geracao sem restart.')


if __name__ == '__main__':
    main()
