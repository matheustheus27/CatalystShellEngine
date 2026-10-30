# 05. Análise Comparativa e Benchmarks

## O que este capítulo demonstra

A avaliação do projeto tem três partes: comportamento funcional, integridade dos artefatos e desempenho medido. Uma suíte aprovada demonstra os casos exercitados naquele ambiente; não comprova compatibilidade com todos os sistemas ou resistência a toda entrada possível.

Não há comparação controlada registrada com outra implementação. Portanto, não são apresentados ganhos de velocidade, consumo de memória ou superioridade sobre outros projetos. O procedimento abaixo permite obter resultados reproduzíveis quando uma medição for necessária.

## Verificação funcional

Execute no Linux ou Ubuntu WSL:

```bash
./catalyst.sh test
```

A suíte cria cópias temporárias no filesystem Linux e cobre:

- Catálogo de capítulos, diretório vazio, nomes com espaços e saída consolidada.
- Sumário, métricas, imagem publicada, permissões e conteúdo do pacote.
- Links inexistentes, fragmentos inválidos, códigos de erro e preservação da publicação.
- SHA-256 do release e relatório com fontes modulares.
- Dois escritores, bloqueio, interrupções, rollback e recuperação de journal.
- Modos de publicação `symlink` e `directory`.
- GET, HEAD, arquivos com espaços, MIME, CSP, nosniff e respostas 400/403/404/405 nos dois previews.
- Início, reinício, parada, liberação da porta e leitura de novas gerações.
- Carregamento dos arquivos da interface com vinte pedidos, até seis conexões simultâneas e sem retries no teste de recursos.
- Expiração de cabeçalhos incompletos no Bash, sem confundir o conteúdo da resposta seguinte.
- No backend concorrente, 32 downloads íntegros com um cliente lento conectado.

As quantidades descrevem os cenários configurados nos testes, não uma garantia de capacidade em produção. A suíte informa o resultado real no terminal.

## Testes da interface e verificação completa

Os testes da interface usam Node 24.22.2 e jsdom, com os bundles locais reais. Eles exercitam títulos repetidos, H6/Setext, cercas, referências por capítulo, caminhos relativos, rollback, DOMPurify, IDs únicos, Mermaid e operação sem recursos externos. A etapa `--project` também carrega a documentação real produzida pelo build.

O jsdom simula o DOM e usa adaptações de geometria SVG para Mermaid; não substitui uma inspeção visual em navegador real. Confira visualmente o sumário, o tema, a responsividade e a impressão antes de uma apresentação.

Com Node/npm disponíveis:

```bash
sudo apt install -y shellcheck python3
npm ci --ignore-scripts --no-audit --no-fund
bash scripts/ci/check.sh
```

O check reúne sintaxe Bash, ShellCheck, sintaxe AWK/JavaScript/Python, testes de integração, build, relatório Markdown, pacote, checksum e testes da interface. A CI do GitHub Actions usa o mesmo ponto de entrada em Ubuntu 22.04 e 24.04 e guarda releases e relatório Markdown. O workflow não exporta o PDF nem comprova, sozinho, a submissão acadêmica.

## Inspeção dos artefatos

```bash
./catalyst.sh all
cat dist/metrics/metrics.txt
head -n 20 dist/docs/summary.md
(cd dist/releases && sha256sum -c catalyst-release-1.0.0.tar.gz.sha256)
tar -tzf dist/releases/catalyst-release-1.0.0.tar.gz
```

O checksum deve conferir com o pacote produzido. Para validar uma cópia recebida, compare também com uma referência obtida por canal confiável. Um arquivo e um checksum alterados juntos podem continuar coerentes; hashes não autenticam o autor.

Para a evidência acadêmica, execute `./catalyst.sh report` e revise o cloc por linguagem. Linhas de documentação, JavaScript e Python não devem ser confundidas com a contagem mínima de Shell.

## Procedimento para medir desempenho

Instale GNU time se necessário (`sudo apt install -y time`) e registre ambiente e entrada:

```bash
uname -a
bash --version
gawk --version
stat -f -c %T .
find docs -type f -name '*.md' -print0 | sort -zV | xargs -0 -r wc -c
/usr/bin/time -v bash catalyst.sh build
/usr/bin/time -v bash catalyst.sh all
```

Registre data, versões, CPU, memória, número de capítulos, volume da entrada, filesystem e saída completa de cada amostra. Separe a primeira execução das execuções aquecidas. Faça várias repetições e apresente mediana e dispersão, além dos dados brutos.

Compare tarefas equivalentes: `all` inclui compactação, enquanto `build` não refaz o release. O build transacional copia a publicação anterior, e relatórios já existentes afetam o volume de trabalho. Mantenha esse estado igual entre as amostras e registre se havia preview ativo.

No WSL, meça separadamente a cópia em `/mnt/p` e a cópia no filesystem Linux, com os mesmos fontes e dependências. O tempo de I/O em uma montagem Windows não deve ser generalizado como custo do algoritmo.

Uma comparação externa exige a mesma entrada, os mesmos artefatos esperados e documentação das dependências de cada solução. Sem esses dados, limite a conclusão ao comportamento observado no próprio projeto.

## Registro da verificação de entrega

Antes de apresentar, anote a revisão dos fontes, o ambiente, os comandos executados e seus resultados. Recompile depois de editar a documentação; gere novamente o relatório e o PDF, revise as páginas e empacote por último. Os comandos estão no [guia acadêmico](../CEFET_REPORT.md).
