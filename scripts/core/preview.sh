#!/usr/bin/env bash
# Template e ativos da interface ficam separados da orquestracao.
generate_html_preview() {
    local base_dir="$1" dist_dir="$2"
    cp "$base_dir/templates/index.html" "$dist_dir/index.html"
    if [ -d "$base_dir/images" ]; then
        mkdir -p "$dist_dir/assets"
        cp -R "$base_dir/images/." "$dist_dir/assets/"
    fi
    echo "Interface HTML criada em: $dist_dir/index.html"
}
