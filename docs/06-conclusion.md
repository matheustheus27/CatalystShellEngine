# 06. Conclusão e Resultados

## Resultado da implementação

O projeto consome capítulos Markdown e gera documentação consolidada, sumário,
métricas, interface HTML e distribuição compactada. Os 20 conceitos são
identificados na CLI e nos módulos efetivamente executados. O relatório acadêmico
resolve as linhas diretamente nos fontes e registra a execução real do `cloc`.

O pipeline retorna falha para referências inválidas, preserva métricas entre
comandos e aceita nomes de capítulos com espaços. O preview valida portas, mantém
estado por usuário/projeto e encerra seu grupo de processos. Os testes utilizam
um diretório temporário Linux e incluem requisições HTTP e entradas inválidas.
O PDF acadêmico é exportado por uma ferramenta Python opcional, separada do núcleo.

## Limites atuais

- O preview Bash é sequencial; o backend Python concorrente é opcional. Ambos são locais.
- O parser cobre um subconjunto de Markdown; não implementa toda a especificação.
- IDs são únicos e normalizados para ASCII. Containers Markdown profundamente
  aninhados e toda a extensão de CommonMark ainda não são cobertos pelo compilador.
- A interface é offline e sanitizada. Novas versões das bibliotecas precisam ser
  incorporadas explicitamente, com revisão dos checksums e das licenças.
- No DrvFS do WSL, leitores externos que ignoram `publish.lock` podem observar
  arquivos de gerações diferentes durante o commit; use filesystem Linux para
  a troca atômica do snapshot inteiro.
- O checksum detecta alterações; autenticidade depende de uma referência confiável.

## Melhorias implementadas nesta revisão

- CLI modular, com uma implementação por responsabilidade e template HTML separado.
- Build transacional com staging privado, bloqueio por projeto e publicação atômica
  por link no Linux; modo DrvFS com journal, rollback e leitura coordenada.
- CI configurado no GitHub Actions com sintaxe, ShellCheck, integração, regressões
  e artefatos, no Ubuntu 22.04 e 24.04. O equivalente local foi validado no WSL.
- Testes para dois escritores, interrupções, falha durante o commit, recuperação
  de journal e preview acompanhando novas gerações.

- Parser com IDs únicos, títulos H1–H6/Setext, cercas por comprimento, referências
  locais por capítulo e validação de fragmentos.
- Bundles locais de Marked, DOMPurify e Mermaid, com integridade verificada e CSP.
- Backend concorrente opcional, com limite de conexões, timeout e publicação coordenada.

## Implementações recomendadas para maior robustez

1. **Validação externa opcional**: verificar URLs por curl com timeout, limite de
   concorrência, cache e tratamento explícito de redirecionamentos e erros de rede.
2. **Releases reproduzíveis**: normalizar timestamps e metadados do tar, produzir
   manifesto de fontes e separar checksums de assinaturas digitais verificáveis.
3. **Observação mais precisa**: usar inotify quando disponível, debounce e monitorar
   também ativos, templates e alterações nos scripts, com fallback por checksum.
4. **Testes de isolamento e falhas**: ampliar a cobertura para falta de dependências, disco cheio e documentos muito grandes.
