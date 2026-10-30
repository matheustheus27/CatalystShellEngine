#!/usr/bin/env python3
"""Entradas externas, saidas isoladas, auditoria e preservacao dos fontes."""
from pathlib import Path
import hashlib
import http.client
import json
import os
import signal
import socket
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]


def digest(directory):
    return {str(file.relative_to(directory)): hashlib.sha256(file.read_bytes()).hexdigest()
            for file in directory.rglob('*') if file.is_file()}


def main():
    with tempfile.TemporaryDirectory(prefix='catalyst-options-') as temporary:
        work = Path(temporary)
        source = work / 'external project'
        docs = source / 'chapters with spaces'
        docs.mkdir(parents=True)
        (source / 'files').mkdir()
        (source / 'files/a b.txt').write_text('External asset\n')
        original = '# External book\n\n## Setup\n\n[Asset](../files/a%20b.txt)\n\n[Section](#setup)\n\n[Outside](https://example.invalid/)\n'
        chapter = docs / '01 chapter.md'
        chapter.write_text(original)
        baseline = digest(source)

        for mode in ['symlink', 'directory']:
            env = {**os.environ, 'CATALYST_PUBLISH_MODE': mode}
            output = work / mode / 'publication a'
            other = work / mode / 'publication b'

            def cli(*args, ok=True):
                result = subprocess.run(['bash', str(ROOT / 'catalyst.sh'), *map(str, args)],
                                        cwd=work, env=env, capture_output=True, text=True, timeout=60)
                assert (result.returncode == 0) == ok, result.stdout + result.stderr
                return result

            def build(destination=output):
                # Opcoes antes/depois do comando e caminhos relativos ao cwd.
                cli('--docs', docs.relative_to(work), 'all', '--output=' + str(destination))

            build()
            before = digest(output)
            assert digest(source) == baseline
            assert (output / 'assets/files/files/a b.txt').read_text() == 'External asset\n'
            assert not (output / 'assets/logo.svg').exists()
            audit = Path(str(output) + '.validation.md')
            report = audit.read_text()
            assert 'APROVADO' in report and '**Referências registradas:** 3' in report
            assert '**Referências locais válidas:** 2' in report
            assert '**URLs externas não consultadas:** 1' in report
            assert 'chapters with spaces/01 chapter.md | 5 |' in report
            assert str(work) not in report
            assert (output / 'reports/validation.md').read_text() == report
            ids = [heading['id'] for heading in json.loads((output / 'docs/headings.json').read_text())]
            assert ids == ['external-book', 'setup']

            chapter.write_text(original + '\n[Missing](missing|<img>.md)\n[Anchor](#absent)\n')
            for command in ['validate', 'all']:
                cli(command, '--docs', docs, '--output', output, ok=False)
                assert digest(output) == before
                report = audit.read_text()
                assert 'REPROVADO' in report and '**Erros:** 2' in report
                assert '&#124;' in report and '&lt;img&gt;' in report
                assert '<img>' not in report
                assert 'Ancora inexistente' in report
            chapter.write_text(original)
            cli('validate', '--docs', docs, '--output', output)
            assert digest(output) == before
            assert 'APROVADO' in audit.read_text()

            # Uma saida nao contamina a outra, inclusive seus servidores e locks.
            chapter.write_text('# Second publication\n')
            build(other)
            assert digest(output) == before
            assert b'Second publication' in (other / 'docs/full-document.md').read_bytes()
            active = []
            try:
                for destination, backend, expected in [(output, 'bash', b'External book'),
                                                        (other, 'threaded', b'Second publication')]:
                    with socket.socket() as probe:
                        probe.bind(('127.0.0.1', 0))
                        port = probe.getsockname()[1]
                    cli('serve', '--output', destination, '--backend', backend, '--port', port)
                    active.append(destination)
                    connection = http.client.HTTPConnection('127.0.0.1', port, timeout=10)
                    try:
                        connection.request('GET', '/docs/full-document.md')
                        response = connection.getresponse()
                        assert response.status == 200 and expected in response.read()
                    finally:
                        connection.close()
            finally:
                for destination in active:
                    cli('serve', '--output', destination, '--stop')

            chapter.write_text(original)
            # Destinos perigosos ou desconhecidos devem preservar os arquivos.
            foreign = work / mode / 'foreign'
            foreign.mkdir()
            (foreign / 'keep.txt').write_text('keep')
            alias = work / mode / 'alias'
            alias.symlink_to(foreign, target_is_directory=True)
            for destination in [source, docs, docs / 'nested', ROOT / 'scripts' / 'generated', foreign,
                                alias, output / 'nested', source / '.catalyst' / 'nested', '/']:
                cli('all', '--docs', docs, '--output', destination, ok=False)
            for args in [('all', '--docs'), ('all', '--output'), ('all', '--docs='),
                         ('all', '--output='), ('all', '--docs', docs, '--output', source / 'files/a b.txt')]:
                cli(*args, ok=False)
            assert (foreign / 'keep.txt').read_text() == 'keep'
            assert digest(source) == baseline

            # Um catalogo vazio tambem gera diagnostico, sem mudar a publicacao.
            empty = source / 'empty'
            empty.mkdir()
            cli('all', '--docs', empty, '--output', output, ok=False)
            assert 'Nenhum capitulo Markdown' in audit.read_text()
            assert digest(output) == before
            empty.rmdir()

            if mode == 'symlink':
                # watch precisa propagar --docs e --output para seus builds filhos.
                with (work / 'watch.log').open('w') as log:
                    watcher = subprocess.Popen(['bash', str(ROOT / 'catalyst.sh'), 'watch',
                                                '--docs', str(docs), '--output', str(output)],
                                               cwd=work, env=env, stdout=log, stderr=log, start_new_session=True)
                    try:
                        deadline = time.monotonic() + 20
                        while 'Publicacao concluida:' not in (work / 'watch.log').read_text():
                            assert watcher.poll() is None and time.monotonic() < deadline
                            time.sleep(0.1)
                        chapter.write_text(original + '\n## Watch changed\n')
                        while b'Watch changed' not in (output / 'docs/full-document.md').read_bytes():
                            assert watcher.poll() is None and time.monotonic() < deadline
                            time.sleep(0.1)
                    finally:
                        os.killpg(watcher.pid, signal.SIGTERM)
                        watcher.wait(timeout=10)
                chapter.write_text(original)
            chapter.write_text('# Publication without assets\n')
            build()
            assert not (output / 'assets/files/files/a b.txt').exists()
            chapter.write_text(original)
            assert digest(source) == baseline
            print(f'Configuracao {mode}: caminhos, isolamento, auditoria, falhas e previews aprovados.')
        print('Watch configuravel e demonstracao sem alteracao dos fontes conferidos.')


if __name__ == '__main__':
    main()
