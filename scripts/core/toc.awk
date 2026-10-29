# Sumario Markdown e metadados JSON vem do mesmo indice de titulos.
function quote(s,    i,c,out) {
    out="\""
    for(i=1;i<=length(s);i++) {
        c=substr(s,i,1)
        if(c=="\\") out=out "\\\\"
        else if(c=="\"") out=out "\\\""
        else out=out c
    }
    return out "\""
}
BEGIN {FS="\t"; print "[" > json}
{
    level=$3; count[level]++
    for(i=level+1;i<=6;i++) count[i]=0
    number=""; indent=""
    for(i=1;i<=level;i++) {if(count[i]==0) count[i]=1; number=number (i>1 ? "." : "") count[i]}
    for(i=1;i<level;i++) indent=indent "   "
    title=$4; gsub(/\[/,"\\[",title); gsub(/\]/,"\\]",title)
    printf "%s%s. [%s](#%s)\n",indent,number,title,$5
    prefix=NR>1 ? ",\n" : ""
    printf("%s{\"title\":%s,\"id\":%s,\"alias\":%s,\"level\":%d,\"number\":%s}", prefix,quote($4),quote($5),quote($6),level,quote(number)) > json
}
END {print "\n]" > json}
