# Entrega acadêmica - Catalyst Shell Engine

- Instituição: CEFET-MG - Engenharia da Computação.
- Disciplina: TEFC: Shell Scripting - 2026/2.
- Aluno: Matheus Thiago de Souza Ferreira.

## Proposta e problema

**Projeto apresentado: Aplicação Shell que cataloga, valida e gera documentação web técnica a partir de arquivos .md.**

A documentação técnica fragmentada em capítulos de arquitetura, visão geral e manuais exige consolidação e manutenção de referências. A proposta apresentada à turma reúne cinco objetivos: ordenar capítulos de `docs/`, higienizar o texto, gerar um sumário hierárquico numerado automaticamente com AWK/sed, validar referências locais com regex e empacotar o release pronto para publicação.

A [visão geral](docs/01-overview.md#proposta-apresentada) preserva a mensagem apresentada. Este guia descreve como produzir as evidências da implementação, não registra uma decisão de aprovação do professor nem uma submissão ao SIGAA.

## Correspondência com a implementação

- **Catálogo e ordem:** descoberta recursiva de `.md`, nomes delimitados por NUL e `sort -zV`.
- **Higienização:** programa sed para CRLF, preservando espaços significativos e os arquivos de origem.
- **Sumário:** GNU AWK indexa H1-H6/Setext e gera numeração hierárquica com IDs únicos.
- **Validação:** regex em GNU AWK e `grep -E`, resolução de links por capítulo, verificação de fragmentos e caminhos canônicos dos ativos.
- **Release:** HTML, Markdown, índices, métricas e ativos em `.tar.gz`, com permissões e checksum SHA-256.

A CLI e os módulos de geração são Shell com AWK/sed e utilitários GNU/Linux. O HTML gerado usa JavaScript e bibliotecas locais para apresentação. O preview padrão é Bash/netcat, o backend Python concorrente é opcional. Python/ReportLab exporta o PDF, Python participa dos testes e Node/jsdom testa a interface. O comando `all` não depende desses runtimes.

A entrada externa são os arquivos Markdown e os ativos, não dados digitados durante a execução. Os usos de `read` recebem arquivos, pipes ou HTTP. Os argumentos da CLI escolhem a operação.

## Requisitos acadêmicos e evidências

O enunciado consultado solicita um script útil, entrada e saída por arquivos, ausência de leitura de dados pelo teclado, pelo menos 30 linhas de código Shell verificadas com cloc e aplicação de no mínimo 15 conceitos distintos. A entrega contém descrição do problema, código numerado e uma planilha com seis colunas: número, conceito, aula, linha, trecho de código e descrição.

O gerador documenta vinte conceitos e resolve arquivo e linha diretamente nos fontes atuais. Se uma evidência não for encontrada, a geração falha. A saída real do cloc discrimina linguagens, confira a contagem Shell para o requisito mínimo. A discussão dos conceitos fica no [capítulo acadêmico](docs/03-concepts.md).

## Gerar o relatório em Markdown

Com as dependências do [manual operacional](docs/04-usage-guide.md) instaladas, execute no Linux ou Ubuntu WSL, dentro do projeto:

```bash
./catalyst.sh all
./catalyst.sh test
./catalyst.sh report
```

O resultado é `dist/reports/sigaa-report.md`, com problema, escopo, planilha, cloc e código integral numerado da CLI, módulos Shell/AWK, backend Python e gerador acadêmico. O relatório não é uma cópia do livro web: ele concentra as evidências para avaliação.

`report` pode aproveitar um snapshot existente. Executar `all` primeiro garante que o livro corresponda aos capítulos atuais. Gere novamente o relatório depois de mudanças de código, para não entregar números de linha antigos.

## Gerar o PDF

Prepare uma vez o exportador opcional no Linux/WSL:

```bash
sudo apt install -y python3 python3-venv fonts-dejavu-core
python3 -m venv .venv-report
.venv-report/bin/python -m pip install reportlab
```

Depois de atualizar a publicação e executar os testes:

```bash
CATALYST_PDF_PYTHON="$PWD/.venv-report/bin/python" ./catalyst.sh report --pdf
./catalyst.sh pack
(cd dist/releases && sha256sum -c catalyst-release-1.0.0.tar.gz.sha256)
```

O PDF fica em `dist/reports/sigaa-report.pdf`. O exportador exige DejaVu em `/usr/share/fonts/truetype/dejavu` e pode usar fontes locais de símbolos, inclusive Segoe UI Emoji no WSL. Sem cobertura de um caractere, o código Unicode é representado textualmente. Revise as páginas, a planilha e a numeração antes da entrega.

`pack` é executado depois do PDF para incluí-lo no release. O botão PDF da interface usa a impressão do livro web e não substitui o relatório acadêmico numerado. Criar o arquivo local também não envia a entrega ao SIGAA.

## Demonstração isolada e evidência de validação

Execute `./catalyst.sh demo` para apresentar a publicação válida, os erros de referência e a preservação da saída. O roteiro usa uma cópia temporária de `examples/demo/`, sem alterar os capítulos de entrega. Para publicar outro conjunto, use `--docs` e `--output`, conforme o manual. A auditoria `<saida>.validation.md` mostra arquivo, linha, destino e motivo da última tentativa; o snapshot aprovado inclui `reports/validation.md`.

## Revisão final

1. Confirme que a descrição continua fiel à proposta apresentada e que cada dependência está declarada.
2. Confira `cloc`, vinte linhas da planilha e correspondência com o código numerado.
3. Verifique capítulos, sumário, links, métricas e diagrama no preview HTTP.
4. Abra o PDF e confira legibilidade, páginas completas, caracteres e tabelas.
5. Confirme o checksum do pacote e os arquivos presentes no release.
6. Submeta o PDF pelo meio solicitado pelo professor e guarde a confirmação da entrega.

Os [testes e medições](docs/05-benchmarks.md) detalham a verificação de desenvolvimento. O [capítulo de limites](docs/06-conclusion.md) delimita as garantias atuais.

## Datas registradas e apresentação

Conforme o enunciado consultado na análise inicial:

- Definição do problema: até 29/09/2026.
- Entrega do relatório PDF: até 03/11/2026.
- Apresentação de Matheus: 17/11/2026, com duração máxima de vinte minutos.
- Avaliação: proposta 2 pontos, relatório 18 e apresentação 10, totalizando 30 pontos.

Confira eventuais alterações comunicadas pelo professor antes da entrega. A agenda acima não substitui o cronograma oficial atualizado.

### Roteiro de demonstração

- **0-3 min:** apresente a proposta, o problema e os capítulos de entrada.
- **3-7 min:** rode `all` e mostre documento, sumário, métricas e release.
- **7-10 min:** mostre a validação de referência local e a preservação da publicação em uma cópia de demonstração.
- **10-15 min:** explique exemplos de Bash, sed, AWK, regex, pipes, parâmetros, permissões e processos, usando a planilha.
- **15-18 min:** abra o preview e mostre os testes e a entrega gerada.
- **18-20 min:** responda perguntas e delimite os recursos opcionais e as limitações.

Prepare os exemplos de falha em uma cópia temporária para manter a versão de entrega íntegra. Instale previamente as dependências, confirme a porta disponível e use os bundles locais para não depender da rede durante a apresentação.
