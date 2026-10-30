# Arquitetura da demonstração

## Fluxo

```mermaid
flowchart LR
    A["Markdown"] --> B["Bash, AWK e sed"]
    B --> C["Validacao"]
    C --> D["Publicacao"]
```

## Configuração

Este título repete um nome do capítulo anterior. Os IDs globais continuam únicos. Volte à [primeira configuração](01-visao-geral.md#configuracao).

O exemplo a seguir é código e não deve gerar erro de referência:

```markdown
[Exemplo que não é uma referência ativa](arquivo-inexistente.md)
```
