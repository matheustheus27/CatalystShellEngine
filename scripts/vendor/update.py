#!/usr/bin/env python3
"""Atualizacao explicita dos bundles offline; nao e executada durante o build."""
import base64
import hashlib
import io
import json
from pathlib import Path
import tarfile
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[2]
PACKAGES = {
    'marked': ('18.1.2', 'lib/marked.umd.js'),
    'dompurify': ('3.4.17', 'dist/purify.min.js'),
    'mermaid': ('12.2.0', 'dist/mermaid.min.js'),
}


def main():
    vendor = ROOT / 'vendor'
    vendor.mkdir(exist_ok=True)
    manifest = {}
    checksums = []
    for name, (version, bundle) in PACKAGES.items():
        metadata_url = f'https://registry.npmjs.org/{name}/{version}'
        with urlopen(metadata_url, timeout=60) as response:
            metadata = json.load(response)
        with urlopen(metadata['dist']['tarball'], timeout=60) as response:
            data = response.read()
        integrity = 'sha512-' + base64.b64encode(hashlib.sha512(data).digest()).decode()
        if integrity not in metadata['dist']['integrity'].split():
            raise ValueError(f'Integridade do pacote {name} nao confere')
        target = vendor / name
        target.mkdir(exist_ok=True)
        with tarfile.open(fileobj=io.BytesIO(data), mode='r:gz') as archive:
            member = archive.getmember('package/' + bundle)
            content = archive.extractfile(member).read()
            destination = target / Path(bundle).name
            destination.write_bytes(content)
            licenses = [m for m in archive.getmembers()
                        if m.isfile() and m.name.count('/') == 1
                        and Path(m.name).name.lower().startswith('license')]
            if not licenses:
                raise ValueError(f'Licenca ausente: {name}')
            license_file = target / 'LICENSE'
            license_file.write_bytes(archive.extractfile(licenses[0]).read())
        for filename in [destination, license_file]:
            relative = filename.relative_to(vendor).as_posix()
            checksums.append(f'{hashlib.sha256(filename.read_bytes()).hexdigest()}  {relative}')
        manifest[name] = {'version': version, 'registry': metadata_url,
                          'tarball': metadata['dist']['tarball'], 'integrity': integrity,
                          'bundle': destination.relative_to(vendor).as_posix()}
        print(name, version, len(content), 'bytes; integridade SHA-512 aprovada')
    (vendor / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (vendor / 'SHA256SUMS').write_text('\n'.join(sorted(checksums)) + '\n')


if __name__ == '__main__':
    main()
