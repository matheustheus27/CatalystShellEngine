#!/usr/bin/env bash
# Template e ativos da interface ficam separados da orquestracao.
generate_html_preview() {
    local base_dir="$1" dist_dir="$2"
    local kind file line target destination source
    (cd "$base_dir/vendor" && sha256sum -c SHA256SUMS >/dev/null)
    mkdir -p "$dist_dir/ui"
    cp "$base_dir/templates/app.css" "$base_dir/templates/app.js" "$dist_dir/ui/"
    cp -R "$base_dir/vendor" "$dist_dir/ui/"
    CSP="$(<"$base_dir/templates/csp.txt")" awk '{gsub(/__CSP__/,ENVIRON["CSP"]); print}' \
        "$base_dir/templates/index.html" > "$dist_dir/index.html"
    if [ -d "$base_dir/images" ]; then
        mkdir -p "$dist_dir/assets"
        cp -R "$base_dir/images/." "$dist_dir/assets/"
    fi
    while IFS=$'\t' read -r kind file line target destination; do
        [ "$kind" = ASSET ] || continue
        source=$(realpath -e "$base_dir/$target")
        [[ "$source" == "$base_dir/"* ]] || { echo "Ativo fora do projeto: $file:$line: $target" >&2; return 1; }
        mkdir -p "$(dirname "$dist_dir/$destination")"
        cp -- "$source" "$dist_dir/$destination"
    done < "$dist_dir/docs/links.tsv"
    echo "Interface HTML criada em: $dist_dir/index.html"
}
