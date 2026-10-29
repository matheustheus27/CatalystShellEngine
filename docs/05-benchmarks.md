# 05. Análise Comparativa e Benchmarks

## Escopo da comparação

O Catalyst Shell Engine é um publicador local de documentação em Bash e utilitários
GNU/Linux. O projeto GlassHub Catalyst é uma referência de contexto; não foi
executada nesta revisão uma comparação controlada entre as duas implementações.

As antigas estimativas de 48 ms, 4,2 MB, 30 KB e ganhos de 250 vezes foram removidas:
o repositório não continha dados brutos, configuração de hardware ou procedimento
que permitisse reproduzir esses resultados.

## Como medir a implementação atual

No Ubuntu WSL, registre a versão do sistema, Bash, quantidade de capítulos, volume
dos arquivos e o tipo de filesystem. O desempenho em `/mnt/p` pode diferir do
filesystem Linux em `/home` ou `/tmp`.

```bash
bash --version
uname -a
wc -c docs/*.md
/usr/bin/time -v bash catalyst.sh all
cloc catalyst.sh scripts/core/server.sh
```

Repita a medição, registre as amostras completas e apresente mediana e dispersão.
Diferencie a primeira execução das seguintes. Para comparação externa, utilize a
mesma entrada e tarefas equivalentes, documentando as dependências de cada projeto.

## Limites conhecidos

- O preview HTTP atende conexões sequencialmente e serve apenas para uso local.
- O núcleo depende de Bash e utilitários GNU/Linux; não é um script POSIX sh.
- A interface web carrega Marked e Mermaid por CDN e exige rede no primeiro acesso.
- Checksums permitem detectar alterações quando comparados a uma referência
  confiável; não constituem assinatura digital nem garantem autenticidade.
