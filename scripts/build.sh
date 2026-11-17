#!/usr/bin/env bash
# Builds the plugins listed in plugins.txt from a tabby-rs checkout and writes the plugin index
# (index.json, index.json.minisig and the .tar.gz packages) into site/.
#
#   scripts/build.sh <tabby-rs checkout>
#
# Environment:
#   BASE_URL                 address the packages are published at (default: relative to index.json)
#   TABBY_PLUGIN_INDEX_KEY   secret key (file contents) to sign index.json with, read from stdin
#   INDEX_KEY_FILE           secret key file to sign with, instead of TABBY_PLUGIN_INDEX_KEY
# Without a key the index is written unsigned; Tabby RS only uses a signed index.
#
# Requires: cargo +1.95.0 and the wasm32-wasip2 target (rustup target add wasm32-wasip2).
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
tabby_rs="$(cd "${1:?usage: scripts/build.sh <tabby-rs checkout>}" && pwd)"
staging="$repo/build/staging"
site="$repo/site"
export CARGO_TARGET_DIR="$repo/build/target"

rm -rf "$staging" "$site"
mkdir -p "$staging"

grep -v -e '^#' -e '^[[:space:]]*$' "$repo/plugins.txt" | while read -r id; do
    dir="$tabby_rs/extensions/$id"
    crate="$(sed -n 's/^name *= *"\(.*\)"/\1/p' "$dir/Cargo.toml" | head -n 1)"
    cargo +1.95.0 build --release --locked --target wasm32-wasip2 --manifest-path "$dir/Cargo.toml"
    mkdir -p "$staging/$id"
    cp -r "$dir/." "$staging/$id/"
    rm -rf "$staging/$id/target"
    cp "$CARGO_TARGET_DIR/wasm32-wasip2/release/${crate//-/_}.wasm" "$staging/$id/plugin.wasm"
done

args=(--extensions "$staging" --out "$site")
if [ -n "${BASE_URL:-}" ]; then args+=(--base-url "$BASE_URL"); fi

cd "$tabby_rs"
if [ -n "${INDEX_KEY_FILE:-}" ]; then
    cargo +1.95.0 xtask plugin-index "${args[@]}" --key "$INDEX_KEY_FILE"
elif [ -n "${TABBY_PLUGIN_INDEX_KEY:-}" ]; then
    printf '%s\n' "$TABBY_PLUGIN_INDEX_KEY" | cargo +1.95.0 xtask plugin-index "${args[@]}" --key -
else
    cargo +1.95.0 xtask plugin-index "${args[@]}"
fi
