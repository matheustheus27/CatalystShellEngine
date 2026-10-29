const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { randomUUID } = require('node:crypto');
const { JSDOM, requestInterceptor, VirtualConsole } = require('jsdom');

const root = path.resolve(__dirname, '../..');
const fixture = fs.mkdtempSync(path.join(os.tmpdir(), 'catalyst-browser-'));
const origin = 'http://localhost:19000';
let dom;
function cli(...args) {
  const result = spawnSync('bash', [path.join(fixture, 'catalyst.sh'), ...args], { encoding: 'utf8', timeout: 60000 });
  return result;
}
function build() {
  const result = cli('all');
  assert.equal(result.status, 0, result.stdout + result.stderr);
}

async function loadInterface(dist) {
  const requests = [];
  const offlineResources = { interceptors: [requestInterceptor(request => {
    const url = request.url;
    requests.push(url);
    assert.equal(new URL(url).origin, origin, 'Tentativa de dependencia externa: ' + url);
    const pathname = decodeURIComponent(new URL(url).pathname);
    return new Response(fs.readFileSync(path.join(dist, pathname)), {
      headers: { 'Content-Type': pathname.endsWith('.css') ? 'text/css' : 'application/javascript' },
    });
  })] };
  const errors = [];
  const warnings = [];
  const virtualConsole = new VirtualConsole();
  virtualConsole.on('warn', (...args) => warnings.push(args.map(String).join(' ')));
  virtualConsole.on('error', (...args) => errors.push(args.map(String).join(' ')));
  virtualConsole.on('jsdomError', error => { if (error.type !== 'css-parsing') errors.push(error.message); });
  let loaded;
  const ready = new Promise(resolve => { loaded = resolve; });
  dom = new JSDOM(fs.readFileSync(path.join(dist, 'index.html'), 'utf8'), {
    url: origin + '/', resources: offlineResources, runScripts: 'dangerously', pretendToBeVisual: true, virtualConsole,
    beforeParse(window) {
      window.addEventListener('catalyst:loaded', loaded);
      window.crypto.randomUUID = randomUUID;
      window.fetch = async url => {
        const parsed = new URL(url, origin);
        requests.push(parsed.href);
        assert.equal(parsed.origin, origin);
        const filename = path.join(dist, decodeURIComponent(parsed.pathname));
        return { ok: fs.existsSync(filename), text: async () => fs.readFileSync(filename, 'utf8'), json: async () => JSON.parse(fs.readFileSync(filename, 'utf8')) };
      };
      Object.defineProperty(window.HTMLElement.prototype, 'innerText', { get() { return this.textContent; } });
      window.HTMLElement.prototype.scrollIntoView = function() {};
      window.SVGElement.prototype.getBBox = () => ({ x: 0, y: 0, width: 100, height: 20 });
      window.SVGElement.prototype.getComputedTextLength = function() { return this.textContent.length * 7; };
      window.matchMedia = () => ({ matches: false, addListener() {}, removeListener() {} });
    },
  });
  let timer;
  await Promise.race([ready, new Promise((_, reject) => { timer = setTimeout(() => reject(new Error('Interface nao carregou: ' + errors.join('\n'))), 20000); })]);
  clearTimeout(timer);
  assert.deepEqual(errors, []);
  return { requests, warnings };
}

async function main() {
  fs.copyFileSync(path.join(root, 'catalyst.sh'), path.join(fixture, 'catalyst.sh'));
  for (const dir of ['scripts', 'templates', 'vendor', 'images']) fs.cpSync(path.join(root, dir), path.join(fixture, dir), { recursive: true });
  fs.mkdirSync(path.join(fixture, 'docs/nested'), { recursive: true });
  fs.mkdirSync(path.join(fixture, 'extras'));
  fs.writeFileSync(path.join(fixture, 'extras/notes.md'), '# External note\n');
  fs.writeFileSync(path.join(fixture, 'images/a b.txt'), 'local asset');
  fs.writeFileSync(path.join(fixture, 'docs/01-intro.md'), [
    '# Repeated title',
    '[Cross reference][target]',
    '[target]: <nested/02-target.md#repeated-title> "Target title"',
    '[Asset](../images/a%20b.txt)',
    '[External note](../extras/notes.md#external-note)',
    '## Sub "quoted" heading',
    '# Repeated title',
    '[Local duplicate](#repeated-title-1)',
    '````md', '# Not a heading', '```', '[Not a link](missing.md)', 'print("x")  ', '````',
    '~~~js', '# Also code', '```', '[Ignored](missing-too.md)', '~~~',
    'Setext title', '============',
    '###### Deep heading',
    '<script>window.__pwned = 1</script>',
    '<img src="https://invalid.example/track.png" onerror="window.__pwned=2">',
    '<img src="\\\\invalid.example/track.png" onerror="window.__pwned=7">',
    '<iframe src="https://invalid.example/frame"></iframe>',
    '<a href="javascript:window.__pwned=3" id="theme-btn">unsafe link</a>',
    '<form name="location"><input name="href"></form>',
    '<svg onload="window.__pwned=4"><script>window.__pwned=5</script></svg>',
    '', '```mermaid', 'flowchart TD', '  A[Local] --> B[Offline]', '```',
  ].join('\n') + '\n');
  fs.writeFileSync(path.join(fixture, 'docs/nested/02-target.md'), '# Repeated title\n[Back](../01-intro.md#repeated-title-1)\n');
  fs.writeFileSync(path.join(fixture, 'docs/03-plain.md'), 'Chapter without heading.\n');
  fs.appendFileSync(path.join(fixture, 'docs/01-intro.md'), '[Plain chapter](03-plain.md)\n');
  build();
  const dist = path.join(fixture, 'dist');
  const headings = JSON.parse(fs.readFileSync(path.join(dist, 'docs/headings.json')));
  assert.equal(new Set(headings.map(h => h.id)).size, headings.length);
  assert.deepEqual(headings.filter(h => h.title === 'Repeated title').map(h => h.id), ['repeated-title', 'repeated-title-1', 'repeated-title-2']);
  assert(headings.some(h => h.title === 'Setext title' && h.level === 1));
  assert(headings.some(h => h.level === 6));
  assert(!headings.some(h => /Not a heading|Also code/.test(h.title)));
  const compiled = fs.readFileSync(path.join(dist, 'docs/full-document.md'), 'utf8');
  assert(compiled.includes('[Cross reference](#repeated-title-2 "Target title")'));
  assert(compiled.includes('[Back](#repeated-title-1)'));
  assert(compiled.includes('assets/files/extras/notes.md#external-note'));
  assert(compiled.includes('print("x")  \n'));
  assert.equal(fs.readFileSync(path.join(dist, 'assets/files/images/a b.txt'), 'utf8'), 'local asset');
  const original = compiled;
  fs.appendFileSync(path.join(fixture, 'docs/nested/02-target.md'), '\n[Broken](../01-intro.md#does-not-exist)\n');
  assert.notEqual(cli('build').status, 0);
  assert.equal(fs.readFileSync(path.join(dist, 'docs/full-document.md'), 'utf8'), original);

  const { requests, warnings } = await loadInterface(dist);
  const document = dom.window.document;
  const rendered = document.getElementById('doc-render');
  assert.equal(dom.window.__pwned, undefined);
  assert.equal(rendered.querySelectorAll('script, iframe, form, object, embed, [onload], [onerror], [srcset]').length, 0);
  assert.equal(rendered.querySelectorAll('a[href^="javascript:"]').length, 0);
  assert.equal(rendered.querySelectorAll('img[src^="http"]').length, 0);
  for (const h of headings) assert(document.getElementById(h.id), h.id);
  for (const id of JSON.parse(fs.readFileSync(path.join(dist, 'docs/chapters.json')))) assert(document.getElementById(id), id);
  const ids = [...document.querySelectorAll('[id]')].map(n => n.id);
  assert.equal(new Set(ids).size, ids.length, 'IDs duplicados no DOM');
  assert.equal(document.querySelectorAll('#toc-container a').length, headings.length);
  assert(rendered.querySelector('.mermaid-container svg'), 'Mermaid local nao produziu SVG: ' + warnings.join('; ') + '; blocos=' + rendered.querySelectorAll('code.language-mermaid').length + '; API=' + typeof dom.window.mermaid);
  assert(document.querySelector('meta[http-equiv="Content-Security-Policy"]').content.includes("script-src 'self'"));
  assert.equal(document.querySelectorAll('script:not([src])').length, 0);
  document.getElementById('theme-btn').click();
  assert(document.body.classList.contains('theme-light'));
  const search = document.getElementById('doc-search');
  search.value = 'Deep heading'; search.dispatchEvent(new dom.window.Event('input'));
  assert.equal([...document.querySelectorAll('#toc-container a')].filter(n => n.style.display !== 'none').length, 1);
  assert(requests.some(url => url.endsWith('mermaid.min.js')));
  console.log('Markdown, caminhos relativos, IDs, rollback, interface offline, Mermaid e sanitizacao aprovados.');
  if (process.argv.includes('--project')) {
    dom.window.close();
    const actual = path.join(root, 'dist');
    const actualHeadings = JSON.parse(fs.readFileSync(path.join(actual, 'docs/headings.json')));
    await loadInterface(actual);
    for (const heading of actualHeadings) assert(dom.window.document.getElementById(heading.id), heading.id);
    assert(dom.window.document.querySelector('#doc-render .mermaid-container svg'), 'Diagrama do projeto nao renderizado');
    console.log('Documentacao real do projeto: titulos e Mermaid offline conferidos.');
  }
}
main().catch(error => { console.error(error); process.exitCode = 1; }).finally(() => {
  dom?.window.close(); fs.rmSync(fixture, { recursive: true, force: true });
});
