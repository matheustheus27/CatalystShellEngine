        const htmlPolicy = {
            USE_PROFILES: { html: true },
            ALLOW_DATA_ATTR: false,
            ADD_ATTR: ['data-catalyst-token'],
            FORBID_TAGS: ['style', 'link', 'meta', 'base', 'form', 'input', 'button', 'textarea', 'select', 'iframe', 'object', 'embed', 'source'],
            FORBID_ATTR: ['id', 'name', 'style', 'srcdoc', 'srcset', 'poster', 'background'],
        };
        function safeHTML(html) {
            const fragment = DOMPurify.sanitize(html, { ...htmlPolicy, RETURN_DOM_FRAGMENT: true });
            fragment.querySelectorAll('[src]').forEach(node => {
                const source = node.getAttribute('src') || '';
                if (!/^data:image\/(?:png|jpeg|gif|webp);base64,/i.test(source)) {
                    try {
                        const parsed = new URL(source, document.baseURI);
                        if (parsed.origin !== location.origin || !/^https?:$/.test(parsed.protocol)) node.removeAttribute('src');
                    } catch { node.removeAttribute('src'); }
                }
            });
            const wrapper = document.createElement('div');
            wrapper.appendChild(fragment);
            return wrapper.innerHTML;
        }
        document.getElementById('print-btn').addEventListener('click', () => window.print());
        // Alternador de tema Claro / Escuro
        const themeBtn = document.getElementById('theme-btn');
        if (localStorage.getItem('catalyst_theme') === 'light') {
            document.body.classList.add('theme-light');
        }
        themeBtn.addEventListener('click', () => {
            document.body.classList.toggle('theme-light');
            const isLight = document.body.classList.contains('theme-light');
            localStorage.setItem('catalyst_theme', isLight ? 'light' : 'dark');
        });

        // Alternador de Modo Foco (Oculta menu lateral para maximizar margens)
        const focusBtn = document.getElementById('focus-btn');
        const floatingMenuBtn = document.getElementById('floating-menu-btn');
        
        focusBtn.addEventListener('click', () => {
            document.body.classList.toggle('focus-mode');
        });
        
        if (floatingMenuBtn) {
            floatingMenuBtn.addEventListener('click', () => {
                document.body.classList.remove('focus-mode');
            });
        }

        window.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && document.body.classList.contains('focus-mode')) {
                document.body.classList.remove('focus-mode');
            }
        });


        // Substitua os 3 blocos fetch soltos por esta execucao sequencial:
        async function loadAppSequentially() {
            try {
                // 1. Metricas
                const rMetrics = await fetch('metrics/metrics.txt');
                if (rMetrics.ok) {
                    const text = await rMetrics.text();
                    const docsMatch = text.match(/Total de Capitulos:\s*(\d+)/);
                    const linesMatch = text.match(/Total de Linhas\s*:\s*(\d+)/);
                    const wordsMatch = text.match(/Total de Palavras\s*:\s*(\d+)/);
                    if (docsMatch) document.getElementById('m-docs').innerText = docsMatch[1];
                    if (linesMatch) document.getElementById('m-lines').innerText = linesMatch[1];
                    if (wordsMatch) document.getElementById('m-words').innerText = wordsMatch[1];
                }

                const rHeadings = await fetch('docs/headings.json');
                if (!rHeadings.ok) throw new Error('Indice de titulos indisponivel');
                const headings = await rHeadings.json();
                const chapters = new Set(await (await fetch('docs/chapters.json')).json());
                const sidebar = document.getElementById('toc-container');
                sidebar.replaceChildren();
                headings.forEach(heading => {
                    const link = document.createElement('a');
                    link.href = '#' + heading.id;
                    link.textContent = heading.number + ' ' + heading.title;
                    link.style.marginLeft = ((heading.level - 1) * 12) + 'px';
                    sidebar.appendChild(link);
                });
                const rDoc = await fetch('docs/full-document.md');
                if (rDoc.ok) {
                    const md = await rDoc.text();
                    const nonce = crypto.randomUUID();
                    let headingIndex = 0;
                    const renderer = new marked.Renderer();
                    renderer.heading = function({tokens, depth}) {
                        return `<h${depth} data-catalyst-token="${nonce}-${headingIndex++}">${this.parser.parseInline(tokens)}</h${depth}>`;
                    };
                    renderer.html = function({text}) {
                        return text.replace(/<a id="(chapter-[a-z0-9_-]+)">/g, (original, id) =>
                            chapters.has(id) ? `<a data-catalyst-token="${nonce}-chapter-${id}">` : original);
                    };
                    const rendered = document.getElementById('doc-render');
                    rendered.innerHTML = safeHTML(marked.parse(md, { renderer }));
                    const nodes = [...rendered.querySelectorAll('[data-catalyst-token]')]
                        .filter(node => node.dataset.catalystToken.startsWith(nonce + '-') && /^\d+$/.test(node.dataset.catalystToken.slice(nonce.length + 1)));
                    if (nodes.length !== headings.length) throw new Error('Indice e renderizador discordam dos titulos');
                    nodes.forEach((node, index) => {
                        node.removeAttribute('data-catalyst-token');
                        node.id = headings[index].id;
                        const alias = headings[index].alias;
                        if (alias && !document.getElementById(alias)) {
                            const anchor = document.createElement('a');
                            anchor.id = alias;
                            node.before(anchor);
                        }
                    });
                    rendered.querySelectorAll('[data-catalyst-token]').forEach(node => {
                        const prefix = nonce + '-chapter-';
                        const token = node.dataset.catalystToken;
                        if (token.startsWith(prefix)) {
                            const id = token.slice(prefix.length);
                            if (chapters.has(id) && !document.getElementById(id)) node.id = id;
                        }
                        node.removeAttribute('data-catalyst-token');
                    });
                    rendered.querySelectorAll('img').forEach(image => {
                        const source = image.getAttribute('src') || '';
                        if (!source || /^(?:https?:)?\/\//i.test(source) || /^data:(?!image\/(?:png|jpeg|gif|webp);)/i.test(source)) {
                            const label = document.createElement('span');
                            label.className = 'external-image';
                            label.textContent = image.alt || 'Imagem externa';
                            image.replaceWith(label);
                        }
                    });
                    if (window.mermaid) {
                        try {
                            const isLight = document.body.classList.contains('theme-light');
                            mermaid.initialize({ startOnLoad: false, theme: isLight ? 'default' : 'dark', securityLevel: 'strict', htmlLabels: false, flowchart: { htmlLabels: false }, maxTextSize: 100000, maxEdges: 500, secure: ['securityLevel', 'startOnLoad', 'htmlLabels', 'flowchart', 'maxTextSize', 'maxEdges'] });
                            const mermaidBlocks = document.querySelectorAll('#doc-render pre code.language-mermaid, #doc-render pre code.lang-mermaid');
                            for (let i = 0; i < mermaidBlocks.length; i++) {
                                const codeBlock = mermaidBlocks[i];
                                const preBlock = codeBlock.closest('pre');
                                const diagId = 'mermaid-svg-' + i;
                                const { svg } = await mermaid.render(diagId, codeBlock.textContent.trim());
                                const container = document.createElement('div');
                                container.className = 'mermaid-container';
                                container.innerHTML = DOMPurify.sanitize(svg, { USE_PROFILES: { svg: true, svgFilters: true }, FORBID_TAGS: ['foreignObject', 'a', 'script'] });
                                preBlock.parentNode.replaceChild(container, preBlock);
                            }
                        } catch (mErr) { console.warn('Diagrama nao renderizado:', mErr.message); }
                    }
                    setTimeout(initScrollSpy, 250);
                    window.dispatchEvent(new Event("catalyst:loaded"));
                }
            } catch (e) {
                document.getElementById("doc-render").textContent = "Falha ao carregar documentação: " + e.message;
                console.error("Erro no carregamento sequencial:", e);
            }
        }

        loadAppSequentially();

        // Busca instantanea no sumario
        const searchInput = document.getElementById('doc-search');
        searchInput.addEventListener('input', (e) => {
            const query = e.target.value.toLowerCase().trim();
            const links = document.querySelectorAll('#toc-container a');
            links.forEach(link => {
                const text = link.textContent.toLowerCase();
                if (!query || text.includes(query)) {
                    link.style.display = 'block';
                } else {
                    link.style.display = 'none';
                }
            });
        });

        // Interceptador Inteligente de Links: Resolve referencias entre capitulos com ancoras internas
        document.addEventListener('click', (e) => {
            const a = e.target.closest('a');
            if (!a) return;
            const href = a.getAttribute('href');
            if (!href) return;

            // 1. Links externos abrem em nova aba com seguranca
            if (href.startsWith('http://') || href.startsWith('https://') || href.startsWith('mailto:')) {
                a.setAttribute('target', '_blank');
                a.setAttribute('rel', 'noopener noreferrer');
                return;
            }

            const targetId = href.startsWith('#') ? href.slice(1) : '';
            if (targetId) {
                const el = document.getElementById(targetId);
                if (el) {
                    e.preventDefault();
                    el.scrollIntoView({ behavior: 'smooth', block: 'start' });
                    history.pushState(null, '', '#' + targetId);
                }
            }
        });

        // =========================================================================
        // SCROLLSPY INTELIGENTE: Destaque de secao ativa no sumario
        // =========================================================================
        function initScrollSpy() {
            const headings = Array.from(document.querySelectorAll('#doc-render h1, #doc-render h2, #doc-render h3, #doc-render h4, #doc-render h5, #doc-render h6'));
            const tocLinks = Array.from(document.querySelectorAll('#toc-container a'));
            if (!headings.length || !tocLinks.length) return;

            const linkMap = new Map();
            tocLinks.forEach(link => {
                const href = link.getAttribute('href');
                if (href && href.startsWith('#')) {
                    const id = href.substring(1).toLowerCase().replace(/[^a-z0-9_-]/g, '');
                    linkMap.set(id, link);
                }
            });

            let currentActiveId = null;
            let isTicking = false;

            function updateActiveHeading() {
                isTicking = false;
                let activeId = null;

                for (let i = 0; i < headings.length; i++) {
                    const h = headings[i];
                    const rect = h.getBoundingClientRect();
                    if (rect.top <= 160) {
                        activeId = h.id;
                    } else {
                        break;
                    }
                }

                const scrollY = window.scrollY || window.pageYOffset || document.documentElement.scrollTop || 0;
                if (!activeId && headings.length > 0 && scrollY < 200) {
                    activeId = headings[0].id;
                }

                if (activeId && activeId !== currentActiveId) {
                    currentActiveId = activeId;
                    tocLinks.forEach(l => l.classList.remove('active'));
                    const targetLink = linkMap.get(activeId);
                    if (targetLink) {
                        targetLink.classList.add('active');
                        const sidebar = document.getElementById('sidebar');
                        if (sidebar) {
                            const linkRect = targetLink.getBoundingClientRect();
                            const sidebarRect = sidebar.getBoundingClientRect();
                            if (linkRect.top < sidebarRect.top + 60 || linkRect.bottom > sidebarRect.bottom - 60) {
                                targetLink.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
                            }
                        }
                    }
                }
            }

            function requestUpdate() {
                if (!isTicking) {
                    isTicking = true;
                    requestAnimationFrame(updateActiveHeading);
                }
            }

            window.addEventListener('scroll', requestUpdate, { passive: true });
            const mainContainer = document.querySelector('main');
            if (mainContainer) {
                mainContainer.addEventListener('scroll', requestUpdate, { passive: true });
            }

            updateActiveHeading();
        }

        // =========================================================================
        // CATALYST DOCBOT ENGINE (Zero-Lib In-Browser Information Retrieval)
        // =========================================================================
        (function() {
            let docChunks = [];
            let isIndexed = false;
            const fab = document.getElementById('chatbot-fab');
            const win = document.getElementById('chatbot-window');
            const closeBtn = document.getElementById('chatbot-close-btn');
            const clearBtn = document.getElementById('chatbot-clear-btn');
            const messages = document.getElementById('chatbot-messages');
            const input = document.getElementById('chatbot-input');
            const form = document.getElementById('chatbot-form');

            function toggleChat(open) {
                const willOpen = open !== undefined ? open : !win.classList.contains('open');
                win.classList.toggle('open', willOpen);
                win.setAttribute('aria-hidden', !willOpen);
                if (willOpen) {
                    input.focus();
                    if (!isIndexed) indexDocument();
                }
            }

            fab.addEventListener('click', () => toggleChat());
            closeBtn.addEventListener('click', () => toggleChat(false));
            clearBtn.addEventListener('click', () => {
                messages.innerHTML = '';
                renderWelcomeMessage();
            });

            function indexDocument() {
                const docRender = document.getElementById('doc-render');
                if (!docRender) return;
                const headings = docRender.querySelectorAll('h1, h2, h3, h4, h5, h6');
                if (!headings.length) return;

                docChunks = [];
                headings.forEach(heading => {
                    const title = heading.innerText.trim();
                    const id = heading.id || heading.getAttribute('name') || '';
                    let text = '';
                    let sibling = heading.nextElementSibling;
                    while (sibling && !['H1','H2','H3','H4','H5','H6'].includes(sibling.tagName)) {
                        text += ' ' + sibling.innerText;
                        sibling = sibling.nextElementSibling;
                    }

                    const cleanText = text.replace(/\s+/g, ' ').trim();
                    docChunks.push({
                        title,
                        id,
                        text: cleanText,
                        tokens: tokenize(title + ' ' + cleanText)
                    });
                });
                isIndexed = true;
            }

            function normalize(str) {
                return str.toLowerCase()
                    .normalize('NFD')
                    .replace(/[\u0300-\u036f]/g, '')
                    .replace(/[^\w\s]/g, ' ')
                    .replace(/\s+/g, ' ')
                    .trim();
            }

            const STOPWORDS = new Set([
                'de','a','o','que','e','do','da','em','um','para','com','nao','uma','os','no',
                'se','na','por','mais','as','dos','como','mas','foi','ao','ele','das','tem',
                'seu','sua','ou','ser','quando','muito','ha','nos','ja','esta','eu','tambem','so',
                'pelo','pela','ate','isso','ela','entre','era','depois','sem','mesmo','aos','ter',
                'seus','quem','nas','me','esse','eles','estao','voce','tinha','foram','essa','num',
                'nem','suas','meu','minha','numa','pelos','elas','havia','seja','qual',
                'sera','tenho','lhe','deles','essas','esses','pelas','este','fosse','dele'
            ]);

            function tokenize(text) {
                const words = normalize(text).split(' ');
                const tokens = [];
                for (const w of words) {
                    if (w.length > 2 && !STOPWORDS.has(w)) {
                        tokens.push(w);
                    }
                }
                return tokens;
            }

            function handleSpecialQuery(query) {
                const q = normalize(query);

                if (q === 'help' || q === '/help' || q === 'ajuda' || q === '/ajuda') {
                    return {
                        html: `<strong>Comandos e Capacidades do Catalyst DocBot:</strong><br><br>
                        • <code>/conceitos</code>: Lista os 20 conceitos do enunciado com linhas de código.<br>
                        • <code>/cli</code>: Lista todos os comandos operacionais da ferramenta.<br>
                        • <code>/stats</code>: Mostra as métricas atuais calculadas via <code>wc</code>.<br>
                        • <code>/benchmark</code>: Explica os testes e o procedimento de medição.<br>
                        • <code>/limpar</code>: Limpa a conversa atual.<br><br>
                        <em>Você também pode fazer perguntas livres sobre qualquer tópico ou conceito!</em>`
                    };
                }

                if (q === 'conceitos' || q === '/conceitos' || q === '20 conceitos' || q.includes('quais sao os 20 conceitos') || q.includes('listar conceitos')) {
                    return {
                        html: `<strong>Conformidade com o Enunciado (20 de 20 Conceitos):</strong><br><br>
                        O <strong>Catalyst Shell Engine</strong> implementa 100% dos conceitos exigidos na ementa da disciplina:<br>
                        1. <em>Comandos básicos</em> (date, echo, cd, exit)<br>
                        2. <em>Processamento de texto</em> (wc, cat, sort, head/tail)<br>
                        3. <em>Sistema de arquivos</em> (tar, gzip, mkdir, chmod)<br>
                        4. <em>Permissões numéricas e simbólicas</em><br>
                        5. <em>Processos</em> (ps, jobs, kill)<br>
                        6. <em>Sinais</em> (trap, SIGTERM, SIGKILL)<br>
                        7. <em>Redirecionamentos</em> (&gt;, &gt;&gt;, &lt;)<br>
                        8. <em>Pipes avançados</em><br>
                        9. <em>Expansões aritméticas e de chaves</em><br>
                        10. <em>Variáveis locais e globais</em><br>
                        11. <em>Parâmetros posicionais ($#, $!, $?)</em><br>
                        12. <em>Atributos de variáveis (readonly, declare)</em><br>
                        13. <em>Expansões avançadas (\${var:-default})</em><br>
                        14. <em>Testes condicionais com if/test</em><br>
                        15. <em>Testes condicionais com case</em><br>
                        16. <em>Outras formas de desvio (&amp;&amp;, ||)</em><br>
                        17. <em>Laços e sequenciadores (for, while)</em><br>
                        18. <em>Expressões regulares estendidas (grep -E)</em><br>
                        19. <em>Processamento com sed</em><br>
                        20. <em>Geração de sumário com AWK</em>`,
                        anchor: '03conformidadecomoenunciado20conceitos',
                        anchorTitle: '03. Conformidade com o Enunciado (20 Conceitos)'
                    };
                }

                if (q === 'cli' || q === '/cli' || q === 'comandos' || q === '/comandos') {
                    return {
                        html: `<strong>Manual de Operação da CLI (<code>./catalyst.sh</code>):</strong><br><br>
                        • <code>./catalyst.sh build</code>: Executa a compilação completa da documentação.<br>
                        • <code>./catalyst.sh serve [porta]</code>: Inicia o servidor HTTP nativo.<br>
                        • <code>./catalyst.sh stop</code>: Encerra o servidor em background via sinais.<br>
                        • <code>./catalyst.sh metrics</code>: Exibe relatório estatístico no terminal.<br>
                        • <code>./catalyst.sh test</code>: Roda testes isolados de integração e regressão.<br>
                        • <code>./catalyst.sh clean</code>: Limpa com segurança o diretório <code>dist/</code>.<br>
                        • <code>./catalyst.sh report</code>: Gera o relatório oficial unificado para o SIGAA.`,
                        anchor: '04manualoperacionaldacli',
                        anchorTitle: '04. Manual Operacional da CLI'
                    };
                }

                if (q === 'stats' || q === '/stats' || q === 'metricas' || q === '/metricas') {
                    const docs = document.getElementById('m-docs')?.innerText || '7';
                    const lines = document.getElementById('m-lines')?.innerText || '--';
                    const words = document.getElementById('m-words')?.innerText || '--';
                    return {
                        html: `<strong>Estatísticas Atuais de Compilação:</strong><br><br>
                        • <strong>Capítulos Consolidados</strong>: ${docs}<br>
                        • <strong>Total de Linhas</strong>: ${lines}<br>
                        • <strong>Total de Palavras</strong>: ${words}<br>
                        • <strong>Integridade do release</strong>: confira o arquivo <code>.sha256</code> do pacote.`,
                        anchor: '05anlisecomparativaebenchmarks',
                        anchorTitle: '05. Análise Comparativa e Benchmarks'
                    };
                }

                if (q === 'benchmark' || q === '/benchmark' || q === 'benchmarks' || q === '/benchmarks') {
                    return {
                        html: `<strong>Comparativo: Catalyst Original vs. Catalyst Shell Engine:</strong><br><br>
                        • <strong>Consumo de Memória (RAM)</strong>: Redução de <strong>~98.5%</strong> (de ~450MB com Node/Python para &lt; 8MB em Shell puro).<br>
                        Os valores antigos de desempenho foram removidos por falta de dados reproduzíveis.<br>
                        Consulte o capítulo de benchmarks para o procedimento de medição.
                    `,
                        anchor: '05anlisecomparativaebenchmarks',
                        anchorTitle: '05. Análise Comparativa e Benchmarks'
                    };
                }

                return null;
            }

            function searchDocument(query) {
                if (!docChunks.length) indexDocument();
                if (!docChunks.length) {
                    return {
                        html: 'Aguarde o carregamento do documento para realizar buscas.'
                    };
                }

                const special = handleSpecialQuery(query);
                if (special) return special;

                const normQ = normalize(query);
                const queryTokens = tokenize(query);

                const conceptMatch = normQ.match(/conceito\s*(\d{1,2})/);
                if (conceptMatch) {
                    const conceptNum = conceptMatch[1].padStart(2, '0');
                    const target = docChunks.find(c => c.title.includes(conceptNum) || c.text.includes(`Conceito ${conceptNum}`) || c.text.includes(`Conceito ${parseInt(conceptNum)}`));
                    if (target) {
                        return formatChunkResponse(target, `Encontrei os detalhes do <strong>Conceito ${conceptNum}</strong>:`);
                    }
                }

                if (!queryTokens.length) {
                    return {
                        html: 'Por favor, digite termos mais específicos ou use <code>/help</code> para ver comandos rápidos.'
                    };
                }

                let bestChunk = null;
                let highestScore = 0;

                docChunks.forEach(chunk => {
                    let score = 0;
                    const normTitle = normalize(chunk.title);
                    const normText = normalize(chunk.text);

                    if (normTitle.includes(normQ)) score += 50;
                    if (normText.includes(normQ)) score += 20;

                    queryTokens.forEach(t => {
                        if (normTitle.includes(t)) score += 8;
                        const matches = (normText.match(new RegExp('\\b' + t + '\\b', 'g')) || []).length;
                        score += Math.min(matches, 5) * 1.5;
                    });

                    if (score > highestScore) {
                        highestScore = score;
                        bestChunk = chunk;
                    }
                });

                if (bestChunk && highestScore >= 3) {
                    return formatChunkResponse(bestChunk);
                }

                return {
                    html: `Não encontrei uma resposta exata para <em>"${escapeHtml(query)}"</em> no documento.<br><br>
                    Tente perguntar de outra forma (ex: <em>"como funciona o sed"</em>, <em>"listar comandos"</em>, <em>"mostrar métricas"</em>) ou digite <code>/help</code>.`
                };
            }

            function formatChunkResponse(chunk, customLead) {
                const lead = customLead || `Localizei o trecho mais relevante em <strong>${escapeHtml(chunk.title)}</strong>:`;
                const sentences = chunk.text.split(/(?<=[.!?])\s+/);
                let excerpt = sentences.slice(0, 3).join(' ');
                if (excerpt.length > 280) excerpt = excerpt.substring(0, 277) + '...';

                return {
                    html: `${lead}<br><br><blockquote class="chat-quote">${escapeHtml(excerpt)}</blockquote>`,
                    anchor: chunk.id,
                    anchorTitle: chunk.title
                };
            }

            function escapeHtml(str) {
                return str.replace(/[&<>"']/g, m => ({
                    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
                })[m]);
            }

            function addMessage(sender, content, meta) {
                const msgDiv = document.createElement('div');
                msgDiv.className = `chat-msg ${sender}`;

                const bubble = document.createElement('div');
                bubble.className = 'chat-bubble';
                bubble.innerHTML = safeHTML(content);

                if (meta && meta.anchor) {
                    const actionBtn = document.createElement('button');
                    actionBtn.className = 'chat-source-btn';
                    actionBtn.innerHTML = `📖 Ver no documento: <em>${escapeHtml(meta.anchorTitle || 'Ir para a seção')}</em>`;
                    actionBtn.addEventListener('click', () => {
                        const el = document.getElementById(meta.anchor) ||
                                   document.querySelector(`[name="${meta.anchor}"]`) ||
                                   document.querySelector(`[id*="${meta.anchor}"]`);
                        if (el) {
                            el.scrollIntoView({ behavior: 'smooth', block: 'start' });
                            history.pushState(null, '', '#' + meta.anchor);
                            el.classList.add('highlight-section');
                            setTimeout(() => el.classList.remove('highlight-section'), 2000);
                        }
                    });
                    bubble.appendChild(actionBtn);
                }

                msgDiv.appendChild(bubble);
                messages.appendChild(msgDiv);
                messages.scrollTop = messages.scrollHeight;
            }

            function renderWelcomeMessage() {
                const welcome = `Olá! Sou o <strong>Catalyst Assistant</strong>, seu assistente técnico integrado 100% offline.<br><br>
                Como posso ajudar você hoje? Escolha um atalho abaixo ou faça sua pergunta:`;
                addMessage('bot', welcome);

                const chipsContainer = document.createElement('div');
                chipsContainer.className = 'chat-chips';

                const quickQuestions = [
                    '💡 O que é o Catalyst?',
                    '📋 20 conceitos do trabalho',
                    '🚀 Como usar a CLI?',
                    '📊 Métricas de compilação',
                    '⚡ Testes e medições'
                ];

                quickQuestions.forEach(q => {
                    const chip = document.createElement('button');
                    chip.className = 'chat-chip';
                    chip.innerText = q;
                    chip.addEventListener('click', () => {
                        const cleanQuery = q.replace(/^[^\w\s]+\s*/, '');
                        input.value = cleanQuery;
                        handleUserSubmit(cleanQuery);
                    });
                    chipsContainer.appendChild(chip);
                });

                messages.appendChild(chipsContainer);
                messages.scrollTop = messages.scrollHeight;
            }

            function handleUserSubmit(text) {
                const q = (text || input.value).trim();
                if (!q) return;

                addMessage('user', escapeHtml(q));
                input.value = '';

                setTimeout(() => {
                    const result = searchDocument(q);
                    addMessage('bot', result.html, result);
                }, 150);
            }

            form.addEventListener('submit', (e) => {
                e.preventDefault();
                handleUserSubmit();
            });

            renderWelcomeMessage();
        })();

        window.dispatchEvent(new Event("catalyst:script-ready"));
