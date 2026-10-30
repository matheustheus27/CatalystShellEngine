# 06. Conclusão e Resultados

## Resultado em relação à proposta

A aplicação implementa o fluxo apresentado ao professor: cataloga e ordena capítulos Markdown, normaliza o texto com sed, gera sumário hierárquico numerado com AWK, valida referências locais com regex e empacota uma publicação web estática. Os arquivos de autoria permanecem separados, e os artefatos gerados ficam em `dist/`.

O núcleo usa Bash e ferramentas GNU/Linux. Os recursos adicionais de interface, preview concorrente e exportação PDF têm suas dependências declaradas. O projeto aplica vinte conceitos de Shell com evidências extraídas dos fontes atuais, sem fixar números de linha ou contagens históricas no manual.

## Robustez implementada

A publicação usa staging privado e bloqueios, com preservação da saída anterior quando o processamento falha. Há publicação por troca de link no Linux e modo compatível com Windows, com journal e recuperação para leitores cooperantes.

O compilador indexa antes de reescrever referências, mantém IDs únicos e compartilha o índice com a interface. Os bundles são locais e verificados, o HTML é sanitizado, e os previews aplicam CSP e contenção de caminhos.

Os testes cobrem falhas, concorrência de escritores, interrupções, recuperação e os dois servidores. O listener Bash permanece aberto entre respostas para atender os pedidos de recursos do navegador sem a perda causada pela recriação da escuta. A verificação completa acrescenta análise estática e testes da interface offline.

As pastas de entrada e saída são configuráveis, com estado independente por publicação. A auditoria Markdown registra a última tentativa, e o exemplo completo demonstra erros intencionais e preservação da saída em cópia temporária.

## Limites atuais

- O parser implementa um subconjunto de Markdown, não toda a especificação CommonMark. Containers profundamente aninhados e codificações URI além das documentadas podem exigir adaptação do conteúdo.
- IDs são normalizados para ASCII. Não se deve presumir equivalência com todos os algoritmos de âncoras de outros renderizadores.
- A validação confere referências locais, não verifica disponibilidade de URLs externas.
- A publicação Linux usa troca de link. Em DrvFS, leitores externos que ignorem o lock podem observar arquivos de gerações diferentes durante o commit.
- O preview Bash é sequencial, o backend Python permite concorrência limitada. Ambos são locais, sem TLS ou autenticação, e não se destinam à produção.
- `watch` consulta checksums de Markdown a cada segundo. Não observa templates ou ativos e não recarrega automaticamente o navegador.
- `pack` e `report` podem aproveitar uma publicação existente, atualizar os fontes exige um novo build antes da entrega.
- SHA-256 verifica integridade contra uma referência confiável, não substitui assinatura digital. O tarball ainda não é reproduzível byte a byte.
- A consulta web funciona offline com os bundles presentes. Instalação de dependências e atualização de bibliotecas podem exigir internet.
- Os testes da interface usam DOM simulado, a apresentação e o PDF também precisam de revisão visual.

## Continuidade recomendada

As próximas melhorias podem manter o mesmo escopo de processamento documental:

1. Validação externa opcional por HTTP, com timeout, cache, limite de concorrência e distinção entre falha de rede e URL inexistente.
2. Releases reproduzíveis, normalizando metadados do tar e registrando um manifesto dos fontes, assinatura digital como recurso separado.
3. Observação por inotify com fallback por checksum, debounce e cobertura de templates, ativos e scripts.
4. Ampliação de casos de falha, como disco cheio, dependências ausentes, arquivos grandes e mais estruturas Markdown.
5. Testes automatizados em navegador real para complementar jsdom e verificar layout, CSP e impressão.

Esses itens são perspectivas de evolução, não funcionalidades declaradas como prontas. O fluxo atual e seus critérios de sucesso estão na [visão geral](01-overview.md), as instruções de operação estão no [manual](04-usage-guide.md).
