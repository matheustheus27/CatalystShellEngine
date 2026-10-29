# Relatório do Projeto: Catalyst Shell Engine

**Instituição**: CEFET-MG — Engenharia da Computação
**Disciplina**: TEFC: Shell Scripting — 2026/2
**Aluno**: Matheus Thiago de Souza Ferreira

## Problema e solução

A documentação técnica dividida em vários arquivos Markdown dificulta a leitura
sequencial, a navegação e a manutenção de referências locais. O projeto consome
`docs/*.md` e produz documento consolidado, sumário hierárquico, métricas, interface
HTML e pacote de distribuição com checksums. A CLI é parametrizada por argumentos.
Os usos de `read` recebem arquivos, pipes ou requisições HTTP, sem solicitar entrada
do teclado.

A descrição entregue deve corresponder ao problema efetivamente enviado à lista
`decom042@googlegroups.com`. Este arquivo não comprova o envio da Etapa 01.

## Relatório reproduzível da Etapa 02

Execute no Linux ou Ubuntu WSL, com Bash e `cloc` instalados:

```bash
bash catalyst.sh report
```

O resultado é `dist/reports/sigaa-report.md`, contendo:

- descrição do problema e da solução;
- planilha de 20 conceitos distintos, com as seis colunas do enunciado;
- arquivo e linha encontrados diretamente na versão atual dos fontes;
- resultado real do `cloc`, sem contagens históricas fixas;
- código integral da CLI, de todos os módulos de `scripts/core/` e do gerador acadêmico, com linhas numeradas.

Os conceitos de processos, sinais e PID são demonstrados no módulo do servidor.
O script `scripts/academic-report.sh` gera o material acadêmico. Parser, sanitizer,
validator, packager, preview e transação são carregados pela CLI. O HTML reside em
`templates/index.html`, separado dos fontes Shell avaliados. A planilha aponta para
o arquivo que realmente executa cada conceito após a modularização.

Para gerar o PDF obrigatório, instale o exportador em um ambiente isolado:

```bash
python3 -m venv .venv-report
.venv-report/bin/python -m pip install reportlab
CATALYST_PDF_PYTHON=.venv-report/bin/python bash catalyst.sh report --pdf
```

São necessárias as fontes DejaVu em `/usr/share/fonts/truetype/dejavu`.
No Ubuntu, os pacotes de apoio são `python3-venv` e `fonts-dejavu-core`.
O PDF será criado em `dist/reports/sigaa-report.pdf`. Python e ReportLab são usados
somente para essa exportação opcional; o pipeline e o servidor permanecem em Bash.
O exportador usa fontes de símbolos locais quando disponíveis (incluindo Segoe UI Emoji no WSL). Sem cobertura, caracteres são representados por seu código Unicode. Revise o PDF antes de submetê-lo ao SIGAA.

## Datas e apresentação

- Etapa 01: definição do problema até 29/09/2026.
- Etapa 02: entrega do relatório em PDF até 03/11/2026.
- Apresentação de Matheus: 17/11/2026, com duração máxima de 20 minutos.

Roteiro sugerido: problema (3 min), pipeline e arquivos gerados (5 min), conceitos
selecionados (6 min), servidor e testes (4 min), fechamento e perguntas (2 min).
A avaliação vale 30 pontos: proposta 2, relatório 18 e apresentação 10.
