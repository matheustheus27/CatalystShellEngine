# 01. Visão Geral e Motivação

## Contexto e Inspiração no GlassHub Catalyst

No desenvolvimento moderno de software, a documentação técnica é um ativo crítico para engenheiros, arquitetos, gestores e novos integrantes de equipe. O [**GlassHub Catalyst**](https://github.com/matheustheus27/GlassHubCatalyst), foi desenvolvido como uma plataforma empresarial projetada para orquestrar compilação tripartite (Python, PHP, Node.js), busca vetorial com RAG (Ollama / LLaMA 3.2), tradução assíncrona orientada a filas RabbitMQ e telemetria Datadog.

Contudo, em pipelines de Integração Contínua (CI/CD), containers enxutos (Scratch/Alpine), instâncias de borda (Edge Computing) ou terminais de administração de servidores, a dependência de runtimes pesados (Python, PHP, Node.js, Docker, etc.) introduz sobrecarga operacional excessiva, lentidão de inicialização e potenciais vulnerabilidades na cadeia de suprimentos.

O **Catalyst Shell Engine** nasce como uma reimaginação arquitetural completa do Catalyst: **100% concebido, implementado e executado em Shell Script nativo (Bash)** para a disciplina **TEFC: Shell Scripting** do **CEFET-MG**.

---

## O Problema do Mundo Real

Em repositórios técnicos de grande porte, a documentação é rotineiramente fragmentada em dezenas de arquivos Markdown distribuídos em subpastas:

1. **Fragmentação de Leitura**: O leitor é forçado a alternar entre arquivos isolados, perdendo a perspectiva linear do sistema como um todo.
2. **Sumários Desatualizados**: Manter links e índices manuais em documentos grandes é uma tarefa propensa a erros, com seções renomeadas e âncoras órfãs.
3. **Inconsistências Léxicas e Sintáticas**: Espaços em branco residuais no final de linhas, formatação irregular de títulos (`##Título` vs `## Título`) e quebras de linha defeituosas poluem o histórico de commits do Git.
4. **Links e Ativos Quebrados**: Referências relativas a imagens ou outros capítulos frequentemente quebram após refatorações de diretórios.
5. **Auditoria e Governança**: Falta de métricas objetivas (linhas, palavras, checksums criptográficos de integridade) que permitam detectar alterações no artefato publicado.

O **Catalyst Shell Engine** resolve todos esses desafios por meio de um único script orquestrador executável (`catalyst.sh`), utilizando apenas o arsenal canônico de utilitários padrão do ambiente GNU/Linux com Bash.

---

## Matriz de Capacidades do Sistema

A tabela abaixo resume as capacidades centrais do Catalyst Shell Engine, comparando a abordagem tradicional pesada com a solução nativa em Shell:

| Capacidade | Solução Tradicional (Multi-Runtime) | Solução Catalyst Shell Engine | Ferramentas Unix Empregadas |
|---|---|---|---|
| **Ingestão Documental** | Scripts Python com `pathlib` e bibliotecas terceiras | Varredura e ordenação natural com globbing | `find -print0`, `sort -zV`, `cat` |
| **Sumário Hierárquico (TOC)** | Bibliotecas AST Markdown complexas | Parser semântico de cabeçalhos de 3 níveis | `awk`, `substr`, `tolower`, `gsub` |
| **Sanitização Léxica** | Linters de terceiros (Prettier, Markdownlint) | Filtros de substituição por expressões regulares | `sed -E`, `s///` |
| **Auditoria de Integridade** | Scripts Node.js com crawlers de links | Varredura léxica com metacaracteres estendidos | `grep -E -o`, `[[ =~ ]]` |
| **Métricas e Telemetria** | Daemons de observabilidade pesados | Contagem e amostragem nativa de I/O | `wc -l`, `wc -w`, `head`, `tail` |
| **Empacotamento de Release** | Ferramentas proprietárias de build | Empacotamento tarball gzip com hashes | `tar`, `gzip`, `chmod`, `md5sum` |
| **Servidor de Pré-visualização** | Web servers complexos (Nginx, Express) | Servidor em background controlado por sinais | `nc -N`, `setsid`, `ps`, `kill` |

---

## Restrições e Conformidade Estrita com o Enunciado

Para garantir conformidade incondicional com as normas do enunciado:
- **Zero Interatividade Bloqueante**: O sistema **não utiliza o comando `read`** nem qualquer chamada interativa de teclado. Toda instrução é parametrizada via argumentos de linha de comando (`$1`, `$@`), possibilitando integração perfeita em scripts headless e pipelines CI/CD.
- **Volume de Código Inspecionado**: Enquanto a disciplina exige um limite mínimo de 30 linhas de código no `cloc`, a contagem atual dos fontes avaliados é produzida pelo comando `report`, usando o `cloc` instalado no ambiente.
- **Exaustividade de Conceitos**: Todos os 20 conceitos do enunciado foram incorporados com propósito funcional real na resolução do problema documental.
