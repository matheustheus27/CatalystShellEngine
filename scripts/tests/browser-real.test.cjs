// Chromium real, com HTTP e CSP reais; nenhuma dependencia externa na pagina.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const net = require('node:net');
const http = require('node:http');
const { spawnSync } = require('node:child_process');
const { chromium } = require('playwright');

const root = path.resolve(__dirname, '../..');
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'catalyst-chromium-'));
const artifacts = path.join(root, '.catalyst/browser-artifacts');
fs.mkdirSync(artifacts, { recursive: true });
let browser;

function toPosix(arg) {
  if (typeof arg !== 'string') return arg;
  if (/^[A-Za-z]:[\\/]/.test(arg)) {
    const drive = arg[0].toLowerCase();
    return `/mnt/${drive}` + arg.slice(2).replace(/\\/g, '/');
  }
  return arg.replace(/\\/g, '/');
}

function cli(...args) {
  const isWin = process.platform === 'win32';
  const command = isWin ? 'wsl' : 'bash';
  const execArgs = isWin
    ? ['bash', toPosix(path.join(root, 'catalyst.sh')), ...args.map(toPosix)]
    : [path.join(root, 'catalyst.sh'), ...args];
  const result = spawnSync(command, execArgs, { encoding: 'utf8', timeout: 90000 });
  assert.equal(result.status, 0, result.stdout + result.stderr);
}

let nextPort = 19100;
async function freePort() {
  if (process.platform === 'win32') {
    const port = nextPort;
    nextPort += 10;
    return port;
  }
  const server = net.createServer();
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const port = server.address().port;
  await new Promise(resolve => server.close(resolve));
  return port;
}

async function waitForHttp(url, timeoutMs = 10000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      await new Promise((resolve, reject) => {
        const req = http.get(url, res => { res.resume(); resolve(); });
        req.on('error', reject);
        req.setTimeout(500, () => req.destroy(new Error('timeout')));
      });
      return;
    } catch {
      await new Promise(r => setTimeout(r, 100));
    }
  }
}

async function verify(output, backend, label, fixture) {
  const port = await freePort();
  const origin = `http://127.0.0.1:${port}`;
  for (const name of fs.readdirSync(artifacts)) {
    if (name.startsWith(label + '-') && /\.(png|zip)$/.test(name)) fs.unlinkSync(path.join(artifacts, name));
  }
  const context = await browser.newContext({ viewport: { width: 1440, height: 960 }, serviceWorkers: 'block' });
  await context.tracing.start({ screenshots: true, snapshots: true });
  const external = [], failures = [], errors = [];
  await context.route('**/*', route => {
    if (new URL(route.request().url()).origin !== origin) {
      external.push(route.request().url());
      return route.abort();
    }
    return route.continue();
  });
  await context.addInitScript(() => {
    window.catalystLoaded = false;
    window.cspViolations = [];
    window.printCalls = 0;
    window.print = () => window.printCalls++;
    window.addEventListener('catalyst:loaded', () => { window.catalystLoaded = true; });
    document.addEventListener('securitypolicyviolation', event => window.cspViolations.push(event.effectiveDirective));
  });
  const page = await context.newPage();
  page.on('pageerror', error => errors.push(error.message));
  page.on('requestfailed', request => failures.push(request.url()));
  cli('serve', '--output', output, '--backend', backend, '--port', String(port));
  await waitForHttp(origin);
  try {
    const response = await page.goto(origin, { waitUntil: 'networkidle' });
    assert.equal(response.status(), 200);
    assert.match(response.headers()['content-security-policy'], /script-src 'self'/);
    await page.waitForFunction(() => window.catalystLoaded);
    assert.equal(await page.locator('body').evaluate(node => getComputedStyle(node).display), 'flex');
    const headings = JSON.parse(fs.readFileSync(path.join(output, 'docs/headings.json'), 'utf8'));
    const ids = await page.locator('#doc-render h1, #doc-render h2, #doc-render h3, #doc-render h4, #doc-render h5, #doc-render h6').evaluateAll(nodes => nodes.map(node => node.id));
    assert.deepEqual(ids, headings.map(heading => heading.id));
    assert.equal(await page.locator('#toc-container a').count(), headings.length);
    await page.locator('.mermaid-container svg').first().waitFor();
    const initialViolations = await page.evaluate(() => window.cspViolations);
    if (fixture) assert.ok(initialViolations.every(value => value === 'script-src-attr'));
    else assert.deepEqual(initialViolations, []);
    assert.equal(await page.locator('#doc-render script, #doc-render iframe, #doc-render [onload], #doc-render [onerror], #doc-render a[href^="javascript:"]').count(), 0);
    assert.equal(await page.evaluate(() => window.__xss), undefined);
    await page.screenshot({ path: path.join(artifacts, `${label}-desktop.png`) });

    const title = headings[headings.length - 1];
    await page.locator('#doc-search').fill(title.title);
    assert.ok(await page.locator('#toc-container a:visible').count() > 0);
    const link = page.locator(`#toc-container a[href="#${title.id}"]`);
    await link.click();
    await page.waitForFunction(id => location.hash === '#' + id, title.id);
    await page.locator('#doc-search').fill('');
    await page.locator('#theme-btn').click();
    assert.equal(await page.locator('body').evaluate(node => node.classList.contains('theme-light')), true);
    await page.reload({ waitUntil: 'networkidle' });
    await page.waitForFunction(() => window.catalystLoaded);
    assert.equal(await page.locator('body').evaluate(node => node.classList.contains('theme-light')), true);
    await page.locator('#focus-btn').click();
    assert.equal(await page.locator('body').evaluate(node => node.classList.contains('focus-mode')), true);
    await page.keyboard.press('Escape');
    assert.equal(await page.locator('body').evaluate(node => node.classList.contains('focus-mode')), false);

    await page.locator('#print-btn').click();
    assert.equal(await page.evaluate(() => window.printCalls), 1);
    await page.emulateMedia({ media: 'print' });
    assert.equal(await page.locator('#sidebar').evaluate(node => getComputedStyle(node).display), 'none');
    const printed = await page.pdf({ format: 'A4', printBackground: true });
    assert.equal(printed.subarray(0, 5).toString(), '%PDF-');
    await page.emulateMedia({ media: 'screen' });
    await page.setViewportSize({ width: 390, height: 844 });
    await page.evaluate(() => window.scrollTo(0, 0));
    assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1), 'Layout transborda em 390px');
    await page.screenshot({ path: path.join(artifacts, `${label}-mobile.png`) });

    // Confirmar que o navegador aplica a CSP, alem da sanitizacao do documento.
    await page.evaluate(() => {
      const script = document.createElement('script');
      script.textContent = 'window.inlineExecuted = true';
      document.body.appendChild(script);
    });
    await page.waitForFunction(() => window.cspViolations.some(value => value.startsWith('script-src')));
    assert.equal(await page.evaluate(() => window.inlineExecuted), undefined);
    if (fixture) {
      const asset = await context.newPage();
      const assetResponse = await asset.goto(origin + '/assets/files/files/active.html');
      assert.match(assetResponse.headers()['content-security-policy'], /^sandbox;/);
      assert.equal(await asset.evaluate(() => window.assetExecuted), undefined);
      await asset.close();
    }
    assert.deepEqual(external, []);
    assert.deepEqual(failures, []);
    assert.deepEqual(errors, []);
    console.log(`Chromium ${label}: CSS/JS, navegacao, temas, foco, 390px, impressao, CSP, Mermaid e offline aprovados.`);
    await context.tracing.stop();
  } catch (error) {
    await page.screenshot({ path: path.join(artifacts, `${label}-failure.png`) }).catch(() => {});
    await context.tracing.stop({ path: path.join(artifacts, `${label}-trace.zip`) });
    throw error;
  } finally {
    await context.close();
    cli('serve', '--output', output, '--stop');
  }
}

async function main() {
  const source = path.join(work, 'source');
  fs.cpSync(path.join(root, 'examples/demo'), source, { recursive: true });
  fs.writeFileSync(path.join(source, 'files/active.html'), '<script>window.assetExecuted=true</script><p>Sandbox asset</p>');
  fs.appendFileSync(path.join(source, 'docs/01-visao-geral.md'), [
    '', '[Active asset](../files/active.html)', '',
    '<script>window.__xss=1</script>', '',
    '<img src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==" onload="window.__xss=2">', '',
    '<iframe src="https://offline.invalid/frame"></iframe>', '',
    '<img src="https://offline.invalid/pixel.png">', '',
  ].join('\n'));
  const output = path.join(work, 'site');
  cli('all', '--docs', path.join(source, 'docs'), '--output', output);
  browser = await chromium.launch();
  for (const backend of ['bash', 'threaded']) await verify(output, backend, backend, true);
  if (process.argv.includes('--project')) await verify(path.join(root, 'dist'), 'threaded', 'project', false);
}

main().catch(error => { console.error(error); process.exitCode = 1; }).finally(async () => {
  if (browser) await browser.close();
  fs.rmSync(work, { recursive: true, force: true });
});
