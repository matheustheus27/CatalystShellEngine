# ⚛️ Demonstração do Catalyst Shell Engine

> Exemplo pequeno para apresentar o fluxo proposto ao professor: ordenar, normalizar, gerar sumário, validar e empacotar.

---

## 📂 Conteúdo

- `docs/01-visao-geral.md`: links internos, títulos repetidos e imagem local.
- `docs/02-arquitetura.md`: diagrama Mermaid e referência de código que não deve ser validada.
- `docs/operacao/03-manual.md`: capítulo em subpasta, link de referência e arquivo com espaços.
- `images/logo.svg` e `files/nota de operacao.txt`: ativos locais da publicação.
- `invalid/99-link-quebrado.md`: erros intencionais, fora da entrada válida.

## 🚀 Demonstração automática

Na raiz do motor, no Linux ou WSL:

```bash
./catalyst.sh demo
```

O comando copia o exemplo para um diretório temporário, publica a versão válida, introduz os erros, verifica o relatório reprovado e confirma que todos os arquivos publicados permanecem iguais. Depois remove o capítulo inválido e valida novamente. O diretório temporário é removido ao terminar, os exemplos versionados e a publicação principal não são alterados.

## 🛠️ Publicar o exemplo para consulta

```bash
./catalyst.sh all --docs examples/demo/docs --output /tmp/catalyst-demo-site
./catalyst.sh serve --output /tmp/catalyst-demo-site --port 8081
```

Abra http://127.0.0.1:8081. A raiz dos ativos é `examples/demo/`, a pasta pai dos capítulos. A auditoria da última execução fica em `/tmp/catalyst-demo-site.validation.md`, a publicação válida inclui `reports/validation.md`.

```bash
./catalyst.sh serve --output /tmp/catalyst-demo-site --stop
```

## 🧪 Demonstração manual de falha

Use uma cópia isolada para não editar os exemplos versionados:

```bash
DEMO_WORK=$(mktemp -d /tmp/catalyst-aula.XXXXXXXX)
cp -R examples/demo/. "$DEMO_WORK/"
./catalyst.sh all --docs "$DEMO_WORK/docs" --output "$DEMO_WORK/site"
cp "$DEMO_WORK/invalid/99-link-quebrado.md" "$DEMO_WORK/docs/"
./catalyst.sh validate --docs "$DEMO_WORK/docs" --output "$DEMO_WORK/site"
# O comando acima deve retornar erro. Consulte o diagnóstico:
cat "$DEMO_WORK/site.validation.md"
```

O relatório identifica o arquivo, a linha, o destino e o motivo. A saída `site/` continua sendo a publicação válida. Depois de remover apenas a cópia do capítulo inválido, execute novamente `all` para atualizar a publicação.
