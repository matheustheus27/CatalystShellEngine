# 04. Manual Operacional da CLI

## Requisitos e Pré-requisitos do Sistema

O **Catalyst Shell Engine** foi desenvolvido para operar nativamente em qualquer sistema operacional compatível com POSIX que forneça um interpretador Bash moderno:

- **Interpretador Shell**: GNU Bash 4.4 ou superior (testado e certificado em Bash 5.0, 5.1 e 5.3).
- **Utilitários do Sistema**: Utilitários padrão do GNU Coreutils (`cat`, `wc`, `sort`, `head`, `tail`, `date`, `chmod`, `mkdir`, `rm`, `nl`).
- **Processadores de Texto e Regex**: `sed` (com suporte a expressões regulares estendidas `-E`), `awk` (POSIX AWK / GNU AWK) e `grep` (com flags `-E` e `-o`).
- **Compressão e Checksum**: `tar`, `gzip`, `md5sum` (com fallback automático em `cksum`).
- **Servidor Web Local (Opcional para preview)**: `python3` ou `python` padrão para o subcomando `serve`.

---

## Permissões e Inicialização

Antes da primeira execução, certifique-se de que o script principal possui permissões de execução adequadas:

```bash
# Conceder permissão de execução (Linux / macOS / Git Bash / WSL)
chmod +x catalyst.sh

# Ativar autocompletar no Bash / Git Bash:
source scripts/completion.bash


# Exibir tela de ajuda e instruções de autocompletar:
./catalyst.sh help
./catalyst.sh completion
```

---

## Matriz Completa de Comandos da CLI

| Subcomando | Descrição Operacional | Efeitos Colaterais / Artefatos Gerados |
|---|---|---|
| `./catalyst.sh all` | Executa o pipeline completo de ponta a ponta (build, sumário, auditoria, métricas, preview web e release compactado). | Gera todos os artefatos organizados sob `dist/`. |
| `./catalyst.sh build` | Consolida todos os capítulos `docs/*.md` na ordem natural, higieniza o texto com `sed`, extrai o sumário com `awk` e compila o `index.html`. | `dist/docs/full-document.md`, `dist/docs/summary.md`, `dist/index.html` |
| `./catalyst.sh validate` | Executa auditoria estrita de links Markdown internos e ativos locais de imagem via expressões regulares `grep -E -o`. | Relatório de validação no console. |
| `./catalyst.sh toc` | Executa exclusivamente o parser em AWK para extrair cabeçalhos e gerar o sumário hierárquico indexado. | `dist/docs/summary.md` |
| `./catalyst.sh sanitize` | Executa o programa em `sed` para remover espaços residuais em fim de linha e normalizar cabeçalhos Markdown. | `dist/docs/full-document.md` |
| `./catalyst.sh stats` | Computa contagem de palavras e linhas via `wc`, extrai amostras de cabeçalho/rodapé e grava o sumário estatístico. | `dist/metrics/metrics.txt` |
| `./catalyst.sh pack` | Compacta os artefatos de distribuição em `.tar.gz`, aplica permissões de segurança octais/simbólicas e gera assinatura `md5sum`. | `dist/releases/catalyst-release-*.tar.gz`, `*.tar.gz.md5` |
| `./catalyst.sh report` | Gera o documento oficial unificado com o código-fonte numerado linha a linha via `nl -ba` pronto para entrega no SIGAA. | `dist/reports/sigaa-report.md` |
| `./catalyst.sh test` | Executa a suíte de testes automatizados com 15 asserções (diretórios, parsing, AWK, regex, servidor, MD5). | Saída de testes colorida no console. |
| `./catalyst.sh watch` | Entra em modo de observação contínua, monitorando `docs/*.md` e recompilando automaticamente a cada salvamento. | Recompilação automática sob demanda. |
| `./catalyst.sh serve` | Inicializa o servidor HTTP local em segundo plano (*background*), armazenando o PID para controle de ciclo de vida. | Processo em background na porta 8000 (ou customizada). |
| `./catalyst.sh serve --stop` | Localiza o PID do servidor em execução e envia sinal de término `SIGTERM` (`kill -15`) com fallback para `SIGKILL` (`kill -9`). | Encerra o processo e limpa `/tmp/catalyst_server.pid`. |
| `./catalyst.sh clean` | Limpa com segurança o diretório de distribuição `dist/`, removendo artefatos intermediários. | Esvazia `dist/`. |
| `./catalyst.sh help` | Imprime a documentação de uso e exemplos práticos formatados no terminal. | Saída padrão. |

---

## Exemplos Práticos de Uso

### 1. Compilação e Publicação Completa
```bash
./catalyst.sh all
```

### 2. Execução da Suíte de Testes Automatizados
```bash
./catalyst.sh test
```
*Saída esperada:*
```text
=================================================================
 🧪 Executando Suíte de Testes Automatizados do Catalyst
=================================================================
  Teste 1: Inicialização de diretórios (init_env)... [PASSOU]
  Teste 2: Permissão 755 no diretório dist... [PASSOU]
  Teste 3: Consolidação de capítulos (consolidate_docs)... [PASSOU]
  Teste 4: Arquivo full-document.md gerado e não vazio... [PASSOU]
  Teste 5: Geração de sumário hierárquico (generate_toc_awk)... [PASSOU]
  Teste 6: Arquivo summary.md gerado e não vazio... [PASSOU]
  Teste 7: Auditoria léxica com grep -E (validate_links_regex)... [PASSOU]
  Teste 8: Cálculo de métricas (compute_statistics)... [PASSOU]
  Teste 9: Arquivo metrics.txt gerado e não vazio... [PASSOU]
  Teste 10: Empacotamento de release tar.gz (package_release)... [PASSOU]
  Teste 11: Tarball de release gerado... [PASSOU]
  Teste 12: Inicialização do servidor HTTP na porta 8999... [PASSOU]
  Teste 13: Encerramento do servidor HTTP via sinal kill... [PASSOU]
  Teste 14: Geração de relatório unificado para o SIGAA... [PASSOU]
  Teste 15: Arquivo sigaa-report.md gerado... [PASSOU]
=================================================================
 ✅ Todos os 15 testes passaram com sucesso!
```

### 3. Geração do Relatório SIGAA com Código Numerado (`nl -ba`)
```bash
./catalyst.sh report
```
Gera `dist/reports/sigaa-report.md` unificando a proposta do problema, o código-fonte integral de `catalyst.sh` com cada linha numerada pelo utilitário `nl -ba` e a planilha de 20 conceitos com números de linhas auditados.

### 4. Modo Observador com Live-Reload
```bash
./catalyst.sh watch
```
Mantém um laço contínuo no terminal. Ao editar e salvar qualquer arquivo em `docs/`, o orquestrador detecta a alteração de timestamp e recompila a documentação imediatamente.

### 5. Servidor de Pré-visualização com Porta Customizada
```bash
# Iniciar na porta padrão (8000)
./catalyst.sh serve

# Iniciar em porta específica (ex: 8080)
./catalyst.sh serve 8080
# ou
./catalyst.sh serve --port 8080

# Encerrar o servidor ativo via sinal kill
./catalyst.sh serve --stop
```

### 6. Recursos da Interface Web Interativa (`index.html`)
- **Raiz Limpa do `dist/`**: O `index.html` reside de forma limpa e isolada na raiz de `dist/`, consumindo automaticamente as subpastas `docs/` e `metrics/`.
- **Busca Instantânea**: Digite no campo `🔍 Buscar no sumário...` para filtrar seções em tempo real.
- **Alternador de Tema**: Clique no botão `🌓 Tema` para alternar entre o tema escuro *glassmorphic* e o tema claro corporativo (a preferência é salva no navegador).
- **Modo Foco / Leitura Ampla**: Oculte a barra lateral com o botão `📐 Foco` e restaure-a a qualquer momento pelo botão flutuante `📑 Sumário`.
- **Exportação para PDF**: Clique no botão `🖨️ PDF` (ou `Ctrl + P`) para imprimir ou salvar como PDF formatado em estilo apostila A4 via regras de estilo `@media print`.
- **Catalyst DocBot (Assistente Virtual Integrado)**:
  - Clique no botão flutuante 💬 no canto inferior direito para abrir a janela de chat.
  - Faça perguntas livres sobre conceitos, comandos ou arquitetura (ex: *"como funciona o sed"*, *"listar comandos"*, *"o que faz o conceito 19"*).
  - Use comandos estilo terminal: `/help`, `/conceitos`, `/cli`, `/stats`, `/benchmark`, `/limpar`.
  - Clique no botão **"📖 Ver no documento"** exibido nas respostas para saltar com scroll suave diretamente até a âncora correspondente no compêndio.

---

## Resolução de Problemas (Troubleshooting)

### A porta do servidor já está em uso
Se a mensagem `A porta 8000 ja possui um processo ativo` for exibida, execute:
```bash
./catalyst.sh serve --stop
```
O orquestrador utilizará `ps` e `kill` para encerrar o processo registrado ou liberará a porta com `fuser -k 8000/tcp`.

### Caracteres CRLF (Windows / DOS)
Caso execute o script em ambiente Linux após clonar no Windows e receber mensagens de erro como `\r: command not found`, converta as quebras de linha:
```bash
sed -i 's/\r$//' catalyst.sh
```
