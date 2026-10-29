# 06. Conclusão e Resultados

## Resultado da implementação

O projeto consome capítulos Markdown e gera documentação consolidada, sumário,
métricas, interface HTML e distribuição compactada. Os 20 conceitos são
identificados no script principal e no módulo de servidor. O relatório acadêmico
resolve as linhas diretamente nos fontes e registra a execução real do `cloc`.

O pipeline retorna falha para referências inválidas, preserva métricas entre
comandos e aceita nomes de capítulos com espaços. O preview valida portas, mantém
estado por usuário/projeto e encerra seu grupo de processos. Os testes utilizam
um diretório temporário Linux e incluem requisições HTTP e entradas inválidas.
O PDF acadêmico é exportado por uma ferramenta Python opcional, separada do núcleo.

## Limites atuais

- O preview HTTP é sequencial e destinado a desenvolvimento local.
- O parser cobre um subconjunto de Markdown; não implementa toda a especificação.
- As âncoras seguem a convenção da interface, que remove espaços e acentos; títulos
  repetidos ainda precisam de identificadores únicos em uma evolução futura.
- A interface depende de bibliotecas em CDN. O HTML dos capítulos é considerado
  confiável; conteúdo recebido de terceiros exige sanitização antes da renderização.
- Builds simultâneos ainda compartilham arquivos temporários e saídas em dist/.
- O checksum detecta alterações; autenticidade depende de uma referência confiável.

## Implementações recomendadas para maior robustez

1. **CI no Linux com ShellCheck**: executar sintaxe, análise estática, integração e
   regressões em todo pull request, usando versões documentadas de Bash e ferramentas.
2. **Build transacional e bloqueio**: usar flock por projeto, diretório temporário
   exclusivo e publicação por troca atômica para preservar a última saída válida.
3. **Consolidar os módulos**: remover duplicação entre a CLI e scripts/core e manter
   uma única implementação para parsing, sanitização, validação e empacotamento.
4. **Parser Markdown mais completo**: tratar títulos repetidos, cercas de tamanhos
   variados, links de referência, caminhos relativos por capítulo e fragmentos de
   arquivos locais com uma convenção única de identificadores.
5. **Interface autossuficiente e sanitizada**: fixar e distribuir dependências locais,
   aplicar sanitização de HTML e uma política CSP compatível com a interface.
6. **Validação externa opcional**: verificar URLs por curl com timeout, limite de
   concorrência, cache e tratamento explícito de redirecionamentos e erros de rede.
7. **Releases reproduzíveis**: normalizar timestamps e metadados do tar, produzir
   manifesto de fontes e separar checksums de assinaturas digitais verificáveis.
8. **Observação mais precisa**: usar inotify quando disponível, debounce e monitorar
   também ativos, templates e alterações nos scripts, com fallback por checksum.
9. **Preview concorrente opcional**: oferecer integração com um servidor estático
   apropriado para múltiplas conexões, mantendo o preview Bash como demonstração.
10. **Testes de isolamento e falhas**: incluir concorrência de builds, interrupção
    durante escrita, falta de dependências, disco cheio e documentos muito grandes.
