# 04. Manual Operacional da CLI

## Ambiente e dependências

Execute em GNU/Linux ou Ubuntu WSL, com Bash e ferramentas GNU. Ubuntu 22.04 e 24.04 são os ambientes configurados na CI, Bash 5.x é recomendado. Não há suporte declarado a PowerShell nativo, POSIX sh, macOS ou Git Bash sem adaptação dos utilitários.

O núcleo usa Bash, coreutils, findutils, grep, sed, GNU AWK (`gawk`), tar, gzip e util-linux (`flock` e `setsid`). `all` não precisa de Python ou Node. O preview exige OpenBSD netcat, incluindo as opções `-N` e `-k`, o backend concorrente acrescenta Python 3.10 ou superior. Os testes de integração usam Python, curl e cloc. O relatório Markdown exige cloc, o PDF acrescenta Python, ReportLab e fontes DejaVu. A verificação completa de desenvolvimento usa ShellCheck, Node 24.22.2 e npm.

Instalar dependências ou atualizar bundles pode exigir internet. O build e a consulta da publicação pronta usam arquivos locais.

## Instalação e execução diretamente no Linux

No Ubuntu ou Debian:

```bash
sudo apt update
sudo apt install -y git bash coreutils findutils grep sed gawk tar gzip util-linux netcat-openbsd curl cloc python3
git clone https://github.com/matheustheus27/CatalystShellEngine.git
cd CatalystShellEngine
chmod +x catalyst.sh
./catalyst.sh help
./catalyst.sh all
./catalyst.sh serve
```

Se o repositório já existe, use sua cópia. Acesse **http://127.0.0.1:8000** e confira sumário, conteúdo, métricas e diagrama. O servidor executa em segundo plano, não é necessário deixar um comando de terminal aberto. Para encerrá-lo:

```bash
./catalyst.sh serve --stop
```

Em outras distribuições, instale os pacotes equivalentes. O projeto usa extensões GNU, portanto substituir gawk por outro awk ou OpenBSD netcat por outra variante pode impedir a execução.

## Execução no Windows com Ubuntu WSL

Caso ainda não tenha Ubuntu WSL, a instalação pode ser solicitada no PowerShell:

```powershell
wsl --install -d Ubuntu
```

Conclua a configuração solicitada pelo Windows e pelo Ubuntu. Para trabalhar, abra o terminal Linux:

```powershell
wsl -d Ubuntu
```

Dentro dele, instale as dependências do procedimento Linux. Para a cópia deste projeto em `P:\Git\GitHub\CatalystShellEngine`:

```bash
cd /mnt/p/Git/GitHub/CatalystShellEngine
bash catalyst.sh all
bash catalyst.sh serve
```

Também é possível chamar a CLI pelo PowerShell, executando-a no WSL:

```powershell
wsl -d Ubuntu --exec bash /mnt/p/Git/GitHub/CatalystShellEngine/catalyst.sh all
wsl -d Ubuntu --exec bash /mnt/p/Git/GitHub/CatalystShellEngine/catalyst.sh serve
wsl -d Ubuntu --exec bash /mnt/p/Git/GitHub/CatalystShellEngine/catalyst.sh test
```

Adapte o caminho à sua máquina. Abra o endereço HTTP no navegador do Windows. Para desempenho e semântica de permissões Linux, uma cópia em `~/projetos/CatalystShellEngine` dentro do WSL é preferível a uma unidade montada em `/mnt/`. A cópia montada continua suportada, com as diferenças transacionais descritas na [arquitetura](02-architecture.md).

## Preparação dos capítulos

Os arquivos de entrada ficam em `docs/`, inclusive em subpastas. Use UTF-8 e a extensão minúscula `.md`. Exemplos de nomes são `01-visao-geral.md`, `02-arquitetura.md` e `10-operacao.md`. A ordenação natural usa o caminho inteiro, organizar subpastas também afeta a sequência.

Use um H1 por capítulo e uma hierarquia progressiva de títulos. Não inclua a numeração do sumário manualmente no texto do título: o AWK a calcula. A documentação deste repositório conserva prefixos de capítulo nos títulos para identificação acadêmica, eles fazem parte do texto, não controlam os contadores.

Exemplo de conteúdo para um novo capítulo:

```markdown
# Operação do projeto

## Preparação

Consulte a [arquitetura](02-architecture.md).

## Identidade visual

![Logotipo](../images/logo.svg)

## Verificação

Execute a validação antes de gerar a publicação.
```

Esse exemplo pressupõe um arquivo diretamente em `docs/`. Em subpastas, ajuste os caminhos a partir do arquivo de origem. O arquivo `docs/07-exemplo.md`, por exemplo, entra na compilação, exemplos que não devem ser publicados precisam ficar fora de `docs/`.

### Markdown reconhecido

O compilador reconhece títulos ATX H1-H6 e Setext, cercas de código com crases ou tils respeitando o comprimento, exemplos indentados, código inline e links inline ou de referência. Há suporte a referências completas, colapsadas e abreviadas no escopo de cada capítulo, além de destinos com parênteses balanceados.

Links entre capítulos viram âncoras do documento consolidado. Um link para um Markdown local fora de `docs/` é tratado como arquivo referenciado, não como um novo capítulo. Referências a arquivos são resolvidas pelo caminho do capítulo, algumas referências antigas relativas à raiz são mantidas por compatibilidade. Para novos documentos, prefira caminhos relativos explícitos.

Títulos recebem IDs ASCII, com normalização de acentos e sufixos como `-1` para repetições. Consulte `dist/docs/headings.json` para os IDs efetivamente gerados. Um link para título repetido deve indicar o sufixo correto dentro do capítulo de destino.

O parser cobre um subconjunto de Markdown, não toda a especificação CommonMark. Containers profundamente aninhados não são plenamente suportados. A decodificação de caminhos cobre espaços e parênteses codificados (`%20`, `%28`, `%29`), não toda codificação URI possível. Nomes de capítulos não podem conter tabulação ou quebra de linha. URLs externas não têm disponibilidade verificada, e imagens remotas são substituídas por texto alternativo na interface offline.

## Pastas configuráveis

As opções comuns `--docs CAMINHO` e `--output CAMINHO` podem aparecer antes ou depois do subcomando; também aceitam a forma `--docs=CAMINHO`. Caminhos relativos são resolvidos a partir do diretório atual do terminal, e caminhos com espaços devem ser colocados entre aspas. Os padrões continuam sendo `docs/` e `dist/` na pasta do motor.

```bash
./catalyst.sh all --docs /caminho/meu-projeto/docs --output /caminho/publicacao
./catalyst.sh validate --docs /caminho/meu-projeto/docs --output /caminho/publicacao
./catalyst.sh watch --docs /caminho/meu-projeto/docs --output /caminho/publicacao
./catalyst.sh serve --output /caminho/publicacao --port 8081
./catalyst.sh serve --output /caminho/publicacao --stop
```

A pasta pai dos capítulos selecionados é a raiz dos arquivos publicáveis. Assim, `--docs /projeto/manuais` permite referências a ativos de `/projeto/`, sem usar as imagens do motor. Templates e bibliotecas continuam vindo do Catalyst. `watch` propaga as duas opções para seus builds filhos. `serve` seleciona a publicação por `--output`; não precisa repetir `--docs`.

As opções também se aplicam a `build`, `toc`, `sanitize`, `stats`, `pack`, `report` e `clean`. Não se aplicam a `test`, `completion` ou `demo`, que têm finalidade própria. `report` sempre descreve o código do motor, mesmo quando a publicação contém capítulos externos.

Cada saída tem seu estado e lock: o destino chamado `dist` usa `.catalyst/` na pasta pai; outros nomes usam uma pasta irmã `.catalyst-<identificador>`. O link de publicação Linux aponta para a geração desse estado. Saídas irmãs podem coexistir, inclusive com previews independentes em portas diferentes.

Para evitar sobrescritas acidentais, o destino deve estar vazio ou conter o marcador `.catalyst-output` criado pelo programa. A publicação padrão legada é aceita para migração. O destino não pode ser a raiz do projeto, conter os fontes, ficar dentro dos capítulos ou de outra publicação, nem ocupar pastas internas do motor ou de estado. `clean` remove os artefatos publicados e mantém o marcador de controle.

## Auditoria de validação em Markdown

`build`, `all` e `validate` geram `<saida>.validation.md` ao lado da publicação. No padrão, o arquivo é `dist.validation.md`. Ele mostra aprovação ou reprovação, total de registros, referências locais válidas, erros e URLs externas não consultadas. A relação detalhada informa resultado, arquivo de origem, linha, destino e motivo.

```bash
./catalyst.sh validate
cat dist.validation.md
```

O arquivo externo registra a última tentativa, inclusive quando ela falha. `validate` não altera a publicação. Builds válidos copiam a auditoria para `<saida>/reports/validation.md`; se o próximo build falhar, essa cópia permanece associada à versão válida e o relatório externo mostra a falha nova. Ambos são texto Markdown; não confunda suas versões.

Cada registro representa uma ocorrência reconhecida pelo parser, não necessariamente uma URL distinta. URLs externas são registradas sem acesso à rede. A linha 0 indica um diagnóstico geral, como catálogo vazio; falhas de preparação anteriores ao início da análise podem encerrar a CLI sem gerar uma auditoria nova.

## Demonstração completa

```bash
./catalyst.sh demo
```

O comando copia `examples/demo/` para um diretório temporário Linux e executa quatro passos: publicação válida; introdução de links inválidos; conferência da auditoria e da preservação integral da saída; remoção da falha e nova validação. Ele não altera os capítulos principais nem os exemplos versionados, e limpa a cópia ao terminar.

Para consultar o exemplo no navegador, publique-o separadamente:

```bash
./catalyst.sh all --docs examples/demo/docs --output /tmp/catalyst-demo-site
./catalyst.sh serve --output /tmp/catalyst-demo-site --port 8081
```

O arquivo `examples/demo/README.md` explica o roteiro manual e os resultados esperados. Os capítulos cobrem títulos repetidos, links por referência, subpastas, Mermaid, imagem local e ativo com espaços. Os erros intencionais ficam em `invalid/`, fora de `docs/`.

## Referência dos comandos

### `all` e `build`

```bash
./catalyst.sh all
./catalyst.sh build
```

Ambos catalogam, consolidam, normalizam, geram sumário, validam referências, calculam métricas e preparam a interface. `all` também refaz o release. Nenhum deles gera o relatório acadêmico automaticamente.

### `validate`

```bash
./catalyst.sh validate
```

Verifica os fontes atuais em staging e retorna falha para referências locais inválidas. Não altera a publicação existente; atualiza apenas a auditoria externa `<saida>.validation.md`. Não consulta URLs externas.

### `toc`, `sanitize` e `stats`

```bash
./catalyst.sh toc
./catalyst.sh sanitize
./catalyst.sh stats
```

Reconstroem o snapshot completo para manter documento, índices e interface coerentes. Não são operações isoladas sobre um único arquivo. `sanitize` normaliza CRLF, preservando espaços significativos, `stats` calcula linhas, palavras, capítulos e amostras. Esses comandos não refazem o pacote de release.

### `pack`

```bash
./catalyst.sh pack
(cd dist/releases && sha256sum -c catalyst-release-1.0.0.tar.gz.sha256)
tar -tzf dist/releases/catalyst-release-1.0.0.tar.gz
```

Empacota a publicação existente, se faltar uma saída básica, executa o build antes. Não detecta sozinho se os fontes foram editados depois do snapshot. Use `all` para publicar conteúdo novo. O pacote contém relatórios já presentes na saída: gere o PDF antes de executar `pack` se ele deve acompanhar o release.

### `serve`

```bash
./catalyst.sh serve                         # Bash, porta 8000.
./catalyst.sh serve --restart --port 8080   # Reinicia e troca a porta.
./catalyst.sh serve --restart               # Preserva porta e backend.
./catalyst.sh serve --stop
```

`serve 8080` também aceita a porta posicional. Há um único preview controlado por usuário e projeto. Para mudar um servidor ativo, use `--restart`. O servidor não executa um build por conta própria e precisa de `dist/` existente.

O modo Bash atende sequencialmente com listener persistente e fila de conexões. Para clientes simultâneos, use Python opcional:

```bash
./catalyst.sh serve --restart --backend threaded --port 8080
```

`--concurrent` é um atalho para `--backend threaded`. Ambos escutam apenas em `127.0.0.1`, acompanham novos builds sem reiniciar e são destinados ao desenvolvimento local.

### `watch`

```bash
./catalyst.sh watch
```

Executa um primeiro build e verifica a cada segundo o checksum dos caminhos e conteúdos de arquivos `.md` em `docs/`. Detecta inclusão, exclusão e edição, não apenas timestamp. Após um erro, mantém a publicação anterior e tenta de novo. Não observa templates, imagens ou bibliotecas, alterá-los exige build manual. Não há recarga automática da aba: atualize o navegador. Use Ctrl+C para encerrar a observação.

### `report`

```bash
./catalyst.sh all
./catalyst.sh report
```

Gera `dist/reports/sigaa-report.md` com problema, solução, planilha dinâmica, cloc e fontes numerados. Se já existe snapshot completo, ele é reaproveitado, por isso execute `all` depois de alterar os capítulos. A preparação do PDF está no [guia acadêmico](../CEFET_REPORT.md).

### `test`

```bash
./catalyst.sh test
```

Executa integração, regressões, transações e HTTP em fixtures temporárias Linux, sem depender de um build prévio no projeto. Python, curl, cloc e os utilitários de execução devem estar disponíveis. Os testes Node da interface são uma etapa adicional da verificação completa descrita no [capítulo de testes](05-benchmarks.md).

### `completion`, `help` e `clean`

```bash
source scripts/completion.bash             # Somente a sessão Bash atual.
./catalyst.sh completion install            # Adiciona configuração ao perfil.
./catalyst.sh completion uninstall          # Remove essa configuração.
./catalyst.sh help
./catalyst.sh clean                         # Remove artefatos; mantém o marcador de controle.
```

A configuração permanente altera o perfil do usuário, é opcional. As definições fornecidas são para Bash. `clean` remove os artefatos da publicação, inclusive relatórios e releases, mantendo `.catalyst-output`; não é necessário para um build normal e não apaga os capítulos de origem. Encerre o preview antes de limpar a saída que ele serve.

## Uso da interface

O painel apresenta sumário hierárquico, busca de títulos, métricas, tema claro/escuro e modo foco. O botão PDF usa a impressão do navegador para a documentação web, não substitui o relatório acadêmico com planilha e código numerado.

O Catalyst Assistant é uma busca local baseada em seções e comandos, sem modelo remoto. Ele não executa comandos no sistema. Mermaid renderiza diagramas localmente, Marked e DOMPurify também são servidos de `ui/vendor/`. Não há dependência de CDN para consultar a publicação.

## Distribuição e manutenção

Extraia o `.tar.gz` em um diretório de publicação e sirva a pasta extraída por HTTP. A consulta é estática, não precisa executar `catalyst.sh`. Configure no servidor os cabeçalhos CSP, nosniff e a política sandbox dos ativos descritos na arquitetura. O preview incluído não deve ser exposto como servidor de produção.

O manifesto `vendor/manifest.json` registra as versões, e `vendor/SHA256SUMS` registra os bundles e licenças. Para atualizar dependências, revise as versões fixadas em `scripts/vendor/update.py`, execute explicitamente `python3 scripts/vendor/update.py` com internet e confira o diff, as licenças, o manifesto e os hashes. Em seguida execute a verificação completa. Não edite um bundle minificado para apenas ajustar seu checksum.

## Solução de problemas

### Página sem estilo ou parada em carregamento

Confirme que está usando o endereço HTTP do preview e que `dist/ui/app.css`, `dist/ui/app.js` e `dist/ui/vendor/` existem. Execute:

```bash
./catalyst.sh all
./catalyst.sh serve --restart
```

Atualize com Ctrl+F5. O servidor Bash mantém o listener entre respostas para não perder os pedidos paralelos de CSS e scripts, os valores CSP são normalizados para impedir CR residual de um checkout Windows. Se persistir, consulte os pedidos e mensagens no painel de rede do navegador e o `server.log` no diretório de estado.

### Dependência ausente ou variante incompatível

Instale os pacotes indicados e confira `gawk --version`, `bash --version` e `nc -h`. O preview exige OpenBSD netcat, mesmo quando o backend concorrente é selecionado pelo controlador atual. Para erro de ReportLab ou fonte, siga a preparação do PDF no guia acadêmico.

### Referência local inválida

Leia o diagnóstico de arquivo, linha e destino. Corrija o caminho no capítulo de origem, verifique capitalização em Linux, fragmento e sufixo de títulos repetidos. Rode `validate` e depois `all`. A última publicação válida permanece disponível quando a validação falha.

### Porta ocupada ou servidor antigo

Use `serve --restart --port 8080` para escolher outra porta. O projeto não encerra processos de terceiros. Depois de alterar o código do servidor, reinicie-o, mudanças apenas nos capítulos são atendidas pelo processo existente após um novo build.

### Permissão de execução ou montagem Windows

Use `bash catalyst.sh all` se o script não estiver executável, ou ajuste `chmod +x` no filesystem Linux. Em DrvFS, permissões dependem das opções de montagem. Não remova locks ou gerações manualmente enquanto houver processos usando o projeto.

### Build interrompido

A próxima operação de escrita ou requisição do preview pode recuperar uma publicação pendente pelo journal. Se houver mensagem de recuperação pendente, preserve `.catalyst/previous` e o estado para diagnóstico. Não edite `dist/` durante a recuperação.
