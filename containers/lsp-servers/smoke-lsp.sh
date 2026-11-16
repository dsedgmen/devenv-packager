#!/usr/bin/env bash
# Smoke-test a per-language LSP image: binary present + LSP initialize where reliable.
# Usage: smoke-lsp.sh <image> <id>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSE=(python3 "$SCRIPT_DIR/parse-tiers.py" "$SCRIPT_DIR/tiers.yaml")

IMAGE="${1:?image required}"
ID="${2:?language id required}"

RUNTIME=podman
command -v podman >/dev/null 2>&1 || RUNTIME=docker

tier="$("${PARSE[@]}" --query tier --id "$ID")"
ship="$("${PARSE[@]}" --query ship --id "$ID")"
binary="$("${PARSE[@]}" --query binary --id "$ID")"

if [[ "$ship" != "true" ]] || [[ -z "$binary" || "$binary" == "None" ]]; then
  echo "FAIL: '$ID' is not shippable (tier=$tier). Cannot smoke." >&2
  exit 1
fi

echo "== smoke $IMAGE id=$ID binary=$binary tier=$tier =="

if ! "$RUNTIME" run --rm --network=none --entrypoint bash "$IMAGE" -lc "command -v $binary >/dev/null"; then
  echo "FAIL: $binary not found in $IMAGE" >&2
  exit 1
fi

# rust-analyzer / clangd can hang on bare initialize; version is enough
case "$ID" in
  rust|c-cpp)
    ver="$("$RUNTIME" run --rm --network=none --entrypoint bash "$IMAGE" -lc "$binary --version" | head -1)"
    echo "OK $ID ($ver)"
    exit 0
    ;;
esac

lsp_initialize_frame() {
  local body
  body='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":null,"clientInfo":{"name":"smoke"},"rootUri":"file:///workspace","capabilities":{},"workspaceFolders":[{"uri":"file:///workspace","name":"workspace"}]}}'
  printf 'Content-Length: %s\r\n\r\n%s' "${#body}" "$body"
}

set +e
out="$(
  { lsp_initialize_frame; sleep 2; } | timeout -s KILL 25s "$RUNTIME" run --rm -i --network=none "$IMAGE" 2>/dev/null | head -c 16384
)"
set -e
if [[ -z "$out" ]]; then
  echo "FAIL: no LSP response from $ID on $IMAGE" >&2
  exit 1
fi
if ! grep -qE 'Content-Length:|jsonrpc|"result"|"error"' <<<"$out"; then
  echo "FAIL: unexpected LSP response from $ID:" >&2
  echo "$out" | head -c 500 >&2
  echo >&2
  exit 1
fi
echo "OK $ID"
