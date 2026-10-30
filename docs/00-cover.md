# ⚛️ Catalyst Shell Engine

> **Manual de Arquitetura e Engenharia de Documentação Técnica**
>
> *Aplicação Shell que cataloga, valida e gera documentação web técnica a partir de arquivos Markdown.*
>
> Projeto desenvolvido para a disciplina **TEFC: Shell Scripting - Engenharia da Computação (CEFET-MG)**

```text
+-----------------------------------------------------------------------+
|  ██████╗  █████╗ ████████╗ █████╗ ██╗  ██╗   ██╗███████╗████████╗     |
| ██╔════╝ ██╔══██╗╚══██╔══╝██╔══██╗██║  ╚██╗ ██╔╝██╔════╝╚══██╔══╝     |
| ██║      ███████║   ██║   ███████║██║   ╚████╔╝ ███████╗   ██║        |
| ██║      ██╔══██║   ██║   ██╔══██║██║    ╚██╔╝  ╚════██║   ██║        |
| ╚██████╗ ██║  ██║   ██║   ██║  ██║███████╗██║   ███████║   ██║        |
|  ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝   ╚══════╝   ╚═╝        |
|                   S H E L L   E N G I N E   |   v 1 . 0 . 0           |
+-----------------------------------------------------------------------+
```

[![GlassHub Bash](https://glasshub-quasar.vercel.app/api/badge?label=Bash&value=5.0%2B&icon=shell&url=https%3A%2F%2Freact.dev&shape=rounded&style=glass&glow=true&theme=glass-dark)](https://www.w3schools.com/bash/)
[![GlassHub CEFET-MG](https://glasshub-quasar.vercel.app/api/badge?label=Instituição&value=CEFET-MG&icon=sparkles&url=https%3A%2F%2Freact.dev&shape=rounded&style=glass&glow=true&theme=glass-dark)](https://www.cefetmg.br)
[![GlassHub Ecossistema](https://glasshub-quasar.vercel.app/api/badge?label=Ecossistema&value=GlassHub&icon=glasshub&url=https%3A%2F%2Freact.dev&shape=rounded&style=glass&glow=true&theme=glass-dark)](https://matheustheus27.github.io/)
[![GlassHub Conceitos](https://glasshub-quasar.vercel.app/api/badge?label=Conceitos&value=20%2F20&icon=star&url=https%3A%2F%2Freact.dev&shape=rounded&style=glass&glow=true&theme=glass-dark)](03-concepts.md)
[![GlassHub Licença](https://glasshub-quasar.vercel.app/api/badge?label=Licença&value=Proprietária&icon=license&url=https%3A%2F%2Freact.dev&shape=rounded&style=glass&glow=true&theme=glass-dark)](https://raw.githubusercontent.com/matheustheus27/CatalystShellEngine/main/LICENSE)

---

## 🏛️ Dados Institucionais e Acadêmicos

| Parâmetro | Detalhe |
|---|---|
| **Instituição** | Centro Federal de Educação Tecnológica de Minas Gerais (CEFET-MG) |
| **Departamento** | Departamento de Computação (DECOM) |
| **Curso** | Engenharia da Computação |
| **Disciplina** | TEFC: Shell Scripting - 2026/2 |
| **Aluno** | Matheus Thiago de Souza Ferreira |
| **Projeto de Referência** | [GlassHub Catalyst](https://github.com/matheustheus27/GlassHubCatalyst) |
| **Artefato Principal** | [`catalyst.sh`](04-usage-guide.md) - CLI e orquestrador |
| **Metodologia** | Automação não interativa, com entrada por arquivos e argumentos |
| **Núcleo** | Bash, GNU AWK, sed e utilitários GNU/Linux |
| **Versão da Aplicação** | 1.0.0 |

---

## 📖 Objetivo deste Manual

Este manual descreve a proposta apresentada à turma, o comportamento implementado e os procedimentos para executar, verificar e demonstrar o projeto. Seus capítulos são também a entrada usada pelo próprio Catalyst Shell Engine: a aplicação processa a documentação que explica seu funcionamento.

O núcleo reúne Bash, GNU AWK, sed e utilitários GNU/Linux. A interface web e as ferramentas opcionais de apoio têm suas tecnologias identificadas ao longo do texto. O propósito acadêmico permanece no processamento de arquivos e na aplicação dos conceitos de Shell.

---

## 📑 Estrutura Deste Livro de Documentação

1. [**Visão geral e motivação**](01-overview.md): proposta, problema e escopo.
2. [**Arquitetura e pipeline**](02-architecture.md): processamento, módulos e publicação.
3. [**Conceitos da disciplina**](03-concepts.md): aplicações verificáveis nos fontes.
4. [**Manual operacional**](04-usage-guide.md): instalação, comandos e exemplos.
5. [**Testes e medições**](05-benchmarks.md): validação funcional e método de medição.
6. [**Conclusão e resultados**](06-conclusion.md): limites e continuidade.

O [README](../README.md) oferece um início rápido. O [guia acadêmico](../CEFET_REPORT.md) concentra a entrega e a apresentação. O relatório com planilha, números de linha e código integral é gerado por `./catalyst.sh report`, sua versão PDF exige `report --pdf`.

---

## 📂 Fontes e Documentos Gerados

Edite os arquivos de `docs/`, os ativos e os templates. A árvore `dist/` é produzida automaticamente e pode ser substituída em uma nova execução. Não edite o livro consolidado para corrigir um capítulo: faça a alteração no arquivo de origem e recompile.

Este manual não substitui o enunciado da disciplina. As evidências de código são obtidas da versão efetivamente executada, evitando contagens e números de linha fixos na documentação.

---

> [!NOTE]
> O livro web consolidado é gerado pelo próprio **Catalyst Shell Engine** a partir destes capítulos. Use `./catalyst.sh build` para atualizar a publicação e `./catalyst.sh all` para gerar também o release. A identidade visual é preservada nos documentos de autoria, os recursos da interface offline seguem os limites descritos no manual.

## 🧪 Exemplo de Demonstração

O comando `./catalyst.sh demo` apresenta o fluxo em uma cópia temporária, com títulos repetidos, subpastas, ativos e referências inválidas. O exemplo versionado fica em `examples/demo/`. O [manual operacional](04-usage-guide.md) explica as opções `--docs` e `--output` e a auditoria Markdown da última tentativa.
