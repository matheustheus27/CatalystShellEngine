# GNU AWK: indice e reescrita usam as mesmas regras para titulos, cercas e links.
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function plain(s) {
    gsub(/<[^>]*>/, "", s)
    s = gensub(/!\[([^]]*)\]\([^)]*\)/, "\\1", "g", s)
    s = gensub(/\[([^]]*)\]\([^)]*\)/, "\\1", "g", s)
    s = gensub(/\[([^]]*)\]\[[^]]*\]/, "\\1", "g", s)
    gsub(/[`*_~]/, "", s); gsub(/&amp;/, "&", s)
    return trim(s)
}
function slug(s) {
    s = tolower(plain(s))
    gsub(/[áàâãäå]/, "a", s); gsub(/[éèêë]/, "e", s)
    gsub(/[íìîï]/, "i", s); gsub(/[óòôõö]/, "o", s)
    gsub(/[úùûü]/, "u", s); gsub(/ç/, "c", s); gsub(/ñ/, "n", s)
    gsub(/[^a-z0-9_ \t-]/, "", s); gsub(/[ \t]+/, "-", s)
    sub(/^-+/, "", s); sub(/-+$/, "", s)
    return s == "" ? "section" : s
}
function legacy(s) { s=tolower(plain(s)); gsub(/[^a-z0-9_-]/,"",s); return s }
function allocate(base, scope,    id,n) {
    id=base; n=0
    while ((scope SUBSEP id) in occupied) id=base "-" ++n
    occupied[scope SUBSEP id]=1
    return id
}
function keyfile(s) { return substr(s, length(root)+2) }
function normalize(s,    a,n,i,result) {
    n=split(s,a,"/"); result=""
    for(i=1;i<=n;i++) {
        if(a[i]=="" || a[i]==".") continue
        if(a[i]=="..") { if(result=="") return "../" s; sub(/(^|\/)[^/]*$/,"",result) }
        else result=result (result=="" ? "" : "/") a[i]
    }
    return result
}
function dirname(s) { sub(/(^|\/)[^/]*$/,"",s); return s }
function labelkey(s) { s=tolower(trim(s)); gsub(/[ \t]+/," ",s); return s }
# Retorna 1 para cercas e seu conteudo, respeitando caractere e comprimento.
function code_line(s,    t,c,n) {
    t=s; sub(/^[ \t]*/,"",t); c=substr(t,1,1)
    if(c=="`" || c=="~") {
        n=0; while(substr(t,n+1,1)==c) n++
        if(fence!="") {
            if(c==fence && n>=fence_length && trim(substr(t,n+1))=="") fence=""
            return 1
        }
        if(n>=3) { fence=c; fence_length=n; return 1 }
    }
    return fence!="" || s ~ /^(    |\t)/
}
function heading(file,line,level,title,    localid,id,old) {
    title=plain(title); gsub(/\t/," ",title); localid=allocate(slug(title),file)
    id=chapters[file] ? allocate(slug(title),"book") : localid
    old=legacy(title)
    headings[++heading_count]="H\t" file "\t" line "\t" level "\t" title "\t" id "\t" localid "\t" old
    if(first[file]=="") first[file]=id
}
# Extrai destino e titulo opcionais sem confundir parenteses dentro da URL.
function destination(s,    i,c,depth,escaped) {
    s=trim(s); dest=""; tail=""; depth=0; escaped=0
    if(substr(s,1,1)=="<") {
        i=index(s,">"); if(!i) return 0
        dest=substr(s,2,i-2); tail=trim(substr(s,i+1)); return 1
    }
    for(i=1;i<=length(s);i++) {
        c=substr(s,i,1)
        if(escaped) { dest=dest c; escaped=0; continue }
        if(c=="\\") { escaped=1; continue }
        if(c=="(") depth++
        if(c==")") depth--
        if(c ~ /[ \t]/ && depth==0) { tail=trim(substr(s,i)); break }
        dest=dest c
    }
    return dest!=""
}
function record(kind,file,line,target,message) {
    gsub(/\t/," ",message); gsub(/\t/," ",target)
    print kind "\t" file "\t" line "\t" target "\t" message > links
}
function url(raw,file,line,    path,fragment,p,candidate,id,sc) {
    if(raw ~ /^(https?:\/\/|mailto:)/) {
        record("EXTERNAL",file,line,raw,"URL externa nao consultada"); return raw
    }
    if(raw ~ /^[A-Za-z][A-Za-z0-9+.-]*:/ || raw ~ /^\/\//) {
        record("ERROR",file,line,raw,"Protocolo nao permitido"); return "#"
    }
    p=index(raw,"#"); path=p ? substr(raw,1,p-1) : raw; fragment=p ? substr(raw,p+1) : ""
    gsub(/%20/," ",path); gsub(/%28/,"(",path); gsub(/%29/,")",path)
    if(path=="") candidate=file
    else {
        candidate=normalize(substr(path,1,1)=="/" ? substr(path,2) : dirname(file) "/" path)
        if(!(candidate in files) && normalize(path) in files) candidate=normalize(path)
    }
    if(!(candidate in files)) {
        record("ERROR",file,line,raw,"Arquivo local inexistente ou fora das fontes publicaveis"); return raw
    }
    if(candidate in first) {
        id=first[candidate]
        if(fragment!="") {
            sc=candidate SUBSEP fragment
            if(sc in anchor) id=anchor[sc]
            else if(candidate==file && fragment in global_anchor) id=global_anchor[fragment]
            else { record("ERROR",file,line,raw,"Ancora inexistente"); return raw }
        }
        if(chapters[candidate]) {
            record("LINK",file,line,raw,"Destino #" id); return "#" id
        }
    } else if(fragment!="") {
        record("ERROR",file,line,raw,"Fragmento so pode ser validado em arquivo Markdown"); return raw
    }
    path="assets/files/" candidate
    record("ASSET",file,line,candidate,path)
    gsub(/ /,"%20",path); gsub(/\(/,"%28",path); gsub(/\)/,"%29",path)
    return path (fragment!="" ? "#" id : "")
}
function closing(s,start,open,closing_char,    i,depth,c) {
    depth=1
    for(i=start+1;i<=length(s);i++) {
        c=substr(s,i,1)
        if(c=="\\") { i++; continue }
        if(c==open) depth++
        if(c==closing_char && --depth==0) return i
        if(c!=closing_char) depth+=0
    }
    return 0
}
function rewrite(s,file,line,    out,i,c,j,k,end,text,ref,raw,extra,ticks,n,stop,span) {
    out=""; i=1
    while(i<=length(s)) {
        c=substr(s,i,1)
        if(c=="\\") { out=out substr(s,i,2); i+=2; continue }
        if(c=="`") {
            n=1; while(substr(s,i+n,1)=="`") n++
            ticks=substr(s,i,n); stop=index(substr(s,i+n),ticks)
            if(stop) { span=n+stop-1+n; out=out substr(s,i,span); i+=span; continue }
        }
        if(c!="[") { out=out c; i++; continue }
        j=closing(s,i,"[","]")
        if(!j) { out=out c; i++; continue }
        text=substr(s,i+1,j-i-1); k=j+1; raw=""; extra=""; end=j
        if(substr(s,k,1)=="(") {
            end=closing(s,k,"(",")")
            if(end && destination(substr(s,k+1,end-k-1))) { raw=dest; extra=tail }
        } else if(substr(s,k,1)=="[") {
            end=closing(s,k,"[","]"); ref=substr(s,k+1,end-k-1)
            if(ref=="") ref=text
            if((file SUBSEP labelkey(ref)) in references) {
                raw=references[file SUBSEP labelkey(ref)]; extra=reference_title[file SUBSEP labelkey(ref)]
            } else if(end) record("ERROR",file,line,ref,"Referencia Markdown nao definida")
        } else if((file SUBSEP labelkey(text)) in references) {
            raw=references[file SUBSEP labelkey(text)]; extra=reference_title[file SUBSEP labelkey(text)]
        }
        if(raw!="") {
            out=out "[" text "](" url(raw,file,line) (extra!="" ? " " extra : "") ")"; i=end+1
        } else { out=out substr(s,i,j-i+1); i=j+1 }
    }
    return out
}
BEGIN {
    while((getline s < chapter_list)>0) chapters[s]=1
    close(chapter_list)
    while((getline s < file_list)>0) files[s]=1
    close(file_list)
    if(mode=="rewrite") {
        print "[" > chapters_file
        FS="\t"
        while((getline s < index_file)>0) {
            split(s,a,"\t")
            if(a[1]=="H") {
                anchor[a[2] SUBSEP a[7]]=a[6]
                if(!((a[2] SUBSEP a[8]) in anchor)) anchor[a[2] SUBSEP a[8]]=a[6]
                if(chapters[a[2]]) {
                    at[a[2] SUBSEP a[3]]=a[6]; used[a[6]]=1; global_anchor[a[6]]=a[6]
                    candidates[++candidate_count]=s
                }
            } else if(a[1]=="F") {
                first[a[2]]=a[3]; chapter_id[a[2]]=a[4]
                if(chapters[a[2]]) {
                    prefix=chapter_json_count++ ? "," : ""
                    printf "%s\"%s\"", prefix, a[4] > chapters_file
                }
            }
            else if(a[1]=="R") { references[a[2] SUBSEP a[3]]=a[4]; reference_title[a[2] SUBSEP a[3]]=a[5] }
        }
        close(index_file)
        print "]" > chapters_file
        for(n=1;n<=candidate_count;n++) {
            split(candidates[n],a,"\t"); old=a[8]
            if(old!="" && !used[old] && !(old in global_anchor)) { aliases[a[6]]=old; global_anchor[old]=a[6] }
            print a[2] "\t" a[3] "\t" a[4] "\t" a[5] "\t" a[6] "\t" aliases[a[6]] > headings_file
        }
        FS=" "
    }
}
FNR==1 {
    file=keyfile(FILENAME); fence=""; previous=""; previous_eligible=0; html=""
    if(mode=="index") { order[++file_count]=file; chapter_id[file]=chapters[file] ? allocate("chapter-" slug(file),"book") : "" }
    else printf "\n<!-- Capitulo: %s -->\n\n<a id=\"%s\"></a>\n\n",file,chapter_id[file]
}
{
    s=$0; sub(/\r$/,"",s)
    if(mode=="rewrite" && (file SUBSEP FNR) in at) {
        id=at[file SUBSEP FNR]
        if(aliases[id]!="") print "<a id=\"" aliases[id] "\"></a>"
        print "<a id=\"" id "\"></a>\n"
    }
    if(code_line(s)) { if(mode=="rewrite") print s; previous_eligible=0; next }
    if(html!="") {
        if(index(tolower(s),html) || (html=="blank" && trim(s)=="")) html=""
        if(mode=="rewrite") print s
        previous_eligible=0; next
    }
    if(match(tolower(s),/^ {0,3}<(script|style|pre|textarea)( |>|$)/,m)) html="</" m[1] ">"
    else if(s ~ /^ {0,3}<!--/ && s !~ /-->/) html="-->"
    else if(s ~ /^ {0,3}<\/?(div|table|section|article|details|summary|blockquote)( |>|$)/) html="blank"
    if(html!="") { if(index(tolower(s),html)) html=""; if(mode=="rewrite") print s; previous_eligible=0; next }
    if(match(s,/^ {0,3}\[([^]]+)\]:[ \t]*(.*)$/,m) && destination(m[2])) {
        if(mode=="index") print "R\t" file "\t" labelkey(m[1]) "\t" dest "\t" tail
        previous_eligible=0; next
    }
    if(mode=="index") {
        if(match(s,/^ {0,3}(#{1,6})([ \t]+|$)(.*)$/,m)) {
            title=m[3]; sub(/[ \t]+#+[ \t]*$/,"",title)
            heading(file,FNR,length(m[1]),title); previous_eligible=0
        } else if(previous_eligible && s ~ /^ {0,3}(=+|-+)[ \t]*$/) {
            heading(file,FNR-1,s ~ /=/ ? 1 : 2,previous); previous_eligible=0
        } else { previous=s; previous_eligible=trim(s)!="" && s !~ /^ {0,3}([-+*>]|[0-9]+[.)])[ \t]/ }
    } else print rewrite(s,file,FNR)
}
END {
    if(mode=="index") {
        for(n=1;n<=heading_count;n++) print headings[n]
        for(n=1;n<=file_count;n++) {
            file=order[n]; print "F\t" file "\t" (first[file]!="" ? first[file] : chapter_id[file]) "\t" chapter_id[file]
        }
    }
}
