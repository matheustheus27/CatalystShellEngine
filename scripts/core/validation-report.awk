# Auditoria Markdown: valores de origem sao texto, nunca Markdown executavel.
function escaped(s) {
    gsub(/&/,"\\&amp;",s); gsub(/</,"\\&lt;",s); gsub(/>/,"\\&gt;",s)
    gsub(/\|/,"\\&#124;",s); gsub(/`/,"\\&#96;",s)
    gsub(/\[/,"\\&#91;",s); gsub(/\]/,"\\&#93;",s)
    gsub(/\r/," ",s)
    return s
}
BEGIN {FS="\t"}
{
    total++
    if($1=="ERROR") errors++
    else if($1=="EXTERNAL") external++
    else valid++
    status=$1=="ERROR" ? "ERRO" : ($1=="EXTERNAL" ? "NAO CONSULTADA" : "OK")
    rows=rows "| " status " | " escaped($2) " | " $3 " | " escaped($4) " | " escaped($5) " |\n"
}
END {
    print "# Relatório de Validação - Catalyst Shell Engine\n"
    print "## Resumo\n"
    print "- **Resultado:** " (errors ? "REPROVADO" : "APROVADO")
    print "- **Referências registradas:** " total+0
    print "- **Referências locais válidas:** " valid+0
    print "- **Erros:** " errors+0
    print "- **URLs externas não consultadas:** " external+0
    print "\nA auditoria considera o subconjunto Markdown suportado. URLs externas são registradas, sem requisições de rede. Linha 0 indica diagnóstico geral.\n"
    print "## Referências e diagnósticos\n"
    if(total) {
        print "| Resultado | Arquivo de origem | Linha | Destino | Observação / motivo |"
        print "|---|---|---|---|---|"
        printf "%s",rows
    } else print "Nenhuma referência reconhecida nos capítulos analisados."
}
