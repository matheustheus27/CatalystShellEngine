# 01. Visão Geral e Motivação

## Proposta apresentada

A mensagem apresentada à turma para apreciação do professor define o projeto:

> **Projeto: Aplicação Shell que cataloga, valida e gera documentação web técnica a partir de arquivos .md**
>
> Pensei em fazer um programa que consolida, valida e gera documentação técnica unificada com base em múltiplos arquivos Markdown de um projeto. Capítulos de arquitetura, manuais de uso, visão geral, etc. Os arquivos base são múltiplos .md fragmentados dentro de uma pasta (docs/), e a ideia é processar tudo em Shell puro:
>
> - ordenar os capítulos.
> - higienizar o texto.
> - gerar um sumário hierárquico numerado automaticamente (1., 1.1., etc.) via AWK/sed.
> - validar as referências locais com regex e empacotar o release final pronto para publicação.

Essa descrição é a referência de escopo. Interface, servidor, testes e relatório apoiam a demonstração e a manutenção desse fluxo.

## Problema resolvido

A documentação de um projeto costuma ser dividida em visão geral, arquitetura, instalação e manuais. Essa separação facilita a autoria, mas cria trabalho adicional para quem precisa de uma versão única para consulta ou entrega.

Ao reunir os arquivos manualmente, é possível inverter capítulos, manter um sumário desatualizado, quebrar links relativos, repetir identificadores de títulos ou esquecer imagens. O problema não é produzir o conteúdo técnico: é consolidar, verificar e distribuir esse conteúdo de forma repetível.

O Catalyst Shell Engine mantém os arquivos de autoria separados e gera uma publicação navegável. A execução pode ser repetida depois de uma alteração e retorna erro quando encontra referências locais inválidas.

## Relação entre proposta e implementação

### Catalogar e ordenar capítulos

O programa percorre `docs/` e suas subpastas, seleciona arquivos `.md` e ordena os caminhos com `sort -zV`. A delimitação por NUL permite nomes com espaços. A ordem é a dos caminhos completos relativos: prefixos numéricos e subpastas devem refletir a leitura desejada.

### Higienizar o texto

Um programa sed normaliza terminações CRLF para LF na saída. Os fontes permanecem intactos. Espaços significativos, indentação, quebras de linha Markdown e conteúdo de exemplos são preservados. A higienização atual não é um formatador geral de Markdown.

### Gerar o sumário numerado

GNU AWK reconhece títulos ATX de H1 a H6 e títulos Setext, desconsidera exemplos em código e calcula identificadores únicos. Outro programa AWK gera o sumário hierárquico numerado a partir desse índice. O mesmo índice alimenta a navegação web.

### Validar referências locais

O compilador identifica links e imagens do subconjunto suportado de Markdown, resolve destinos a partir de cada capítulo e verifica fragmentos de títulos. O validador usa regex estendida com `grep -E` para identificar diagnósticos do índice e confere ativos por caminho canônico. Referências inexistentes ou destinos fora do projeto impedem a publicação.

### Empacotar a publicação

O programa gera HTML, Markdown consolidado, sumário, índices, métricas e ativos, depois cria um `.tar.gz` com `tar` e gzip. Um SHA-256 permite conferir a integridade do pacote. O release é uma publicação estática que deve ser servida por HTTP, não exige o servidor de desenvolvimento original.

## Fronteira do núcleo em Shell

O processamento proposto é implementado com Bash e programas AWK/sed, apoiados por utilitários GNU/Linux. O comando `all` funciona sem Python, Node ou downloads durante o build.

A publicação contém JavaScript para renderizar Markdown e oferecer busca, temas e diagramas. O preview padrão é Bash com OpenBSD netcat, há um backend Python concorrente opcional. A exportação PDF usa Python/ReportLab. Os testes HTTP usam Python, e os testes da interface usam Node/jsdom. Essas dependências não substituem os cinco objetivos no núcleo Shell.

O programa recebe parâmetros pela CLI e conteúdo por arquivos. `read` aparece em laços e no servidor, com entrada proveniente de arquivos, pipes ou HTTP, não há perguntas pelo teclado.

## Critérios de sucesso

- Os capítulos aparecem na ordem definida pelos caminhos de origem.
- Títulos válidos produzem entradas numeradas e destinos únicos.
- Um link local inválido faz a execução falhar e preserva a última publicação válida.
- Ativos necessários acompanham a documentação.
- O pacote é extraível e seu SHA-256 confere.
- O preview carrega conteúdo, estilo e scripts sem CDN.
- A entrega acadêmica registra a contagem real de código e as evidências dos conceitos.

Os [testes e medições](05-benchmarks.md) explicam a verificação. Os [limites](06-conclusion.md) delimitam o Markdown, o ambiente e as garantias atuais.

## Reutilização e demonstração

`--docs` e `--output` permitem aplicar o fluxo a outro projeto, mantendo os recursos de apresentação do motor. A auditoria Markdown detalha as referências e os motivos de erro da última tentativa. O exemplo `examples/demo/` e o comando `demo` demonstram títulos repetidos, subpastas, ativos e falhas sem modificar a documentação principal.
