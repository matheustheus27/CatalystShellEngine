#!/usr/bin/env python3
"""Igualdade binaria dos releases, metadados e conteudo sensivel a alteracoes."""
from pathlib import Path
import hashlib
import os
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[2]
EPOCH = '1700000000'


def main():
    with tempfile.TemporaryDirectory(prefix='catalyst-repro-') as temporary:
        work = Path(temporary)
        docs = work / 'source/docs'
        docs.mkdir(parents=True)
        chapter = docs / '01.md'
        chapter.write_text('# Reproducible book\n\n## Section\n\nContent.\n')
        first, second = work / 'first', work / 'second'

        def cli(command, output, *, env=None, ok=True, mask=0o022):
            selected = {**os.environ, 'SOURCE_DATE_EPOCH': EPOCH, 'TZ': 'Pacific/Honolulu', **(env or {})}
            result = subprocess.run(['bash', str(ROOT / 'catalyst.sh'), command,
                                     '--docs', str(docs), '--output', str(output)],
                                    env=selected, capture_output=True, text=True, timeout=90, umask=mask)
            assert (result.returncode == 0) == ok, result.stdout + result.stderr

        def archive(output):
            return output / 'releases/catalyst-release-1.0.0.tar.gz'

        cli('all', first)
        original = archive(first).read_bytes()
        assert original[4:8] == b'\0\0\0\0' and not (original[3] & 8)
        with tarfile.open(archive(first)) as package:
            names = package.getnames()
            assert 'index.html' in names and 'reports/validation.md' in names
            for member in package:
                assert member.uid == member.gid == 0
                assert member.mtime == int(EPOCH)
                assert member.mode == (0o755 if member.isdir() else 0o644)

        for file in first.rglob('*'):
            if file.is_file():
                file.chmod(0o700)
                os.utime(file, (1800000000, 1800000000))
        cli('pack', first, env={'TAR_OPTIONS': '--mtime=2000-01-01', 'GZIP': '-1'})
        assert archive(first).read_bytes() == original, 'Metadados ou ambiente alteraram o pacote'
        cli('all', second, env={'TZ': 'Asia/Tokyo'}, mask=0o077)
        assert archive(second).read_bytes() == original, 'Builds independentes divergiram'

        # O relatorio omite somente o tempo/taxas variaveis do cloc; contagens reais ficam.
        cli('report', first)
        cli('report', second, env={'TZ': 'Asia/Tokyo'})
        assert (first / 'reports/sigaa-report.md').read_bytes() == (second / 'reports/sigaa-report.md').read_bytes()
        cli('pack', first)
        cli('pack', second)
        with_report = archive(first).read_bytes()
        assert with_report == archive(second).read_bytes()
        for invalid in ['', '-1', 'abc', '1.2', '999999999999999999999999']:
            cli('all', first, env={'SOURCE_DATE_EPOCH': invalid}, ok=False)
            assert archive(first).read_bytes() == with_report
        chapter.write_text('# Reproducible book\n\nChanged content.\n')
        cli('all', second)
        assert hashlib.sha256(archive(second).read_bytes()).digest() != hashlib.sha256(with_report).digest()
        print('Releases: igualdade binaria, epoch, permissoes, ambiente, relatorio e alteracao de conteudo aprovados.')


if __name__ == '__main__':
    main()
