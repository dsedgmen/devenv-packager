#!/usr/bin/env bash
# Smoke-test a per-language LSP image: binary present + LSP initialize where reliable.
# Usage:
#   smoke-lsp.sh <image> <id>                 # shippable only
#   smoke-lsp.sh --provisional <image> <id>   # red candidates (binary required)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSE=(python3 "$SCRIPT_DIR/parse-tiers.py" "$SCRIPT_DIR/tiers.yaml")

PROVISIONAL=false
if [[ "${1:-}" == "--provisional" ]]; then
  PROVISIONAL=true
  shift
fi

IMAGE="${1:?image required}"
ID="${2:?language id required}"

RUNTIME=podman
command -v podman >/dev/null 2>&1 || RUNTIME=docker

tier="$("${PARSE[@]}" --query tier --id "$ID")"
ship="$("${PARSE[@]}" --query ship --id "$ID")"
binary="$("${PARSE[@]}" --query binary --id "$ID")"

if [[ -z "$binary" || "$binary" == "None" ]]; then
  echo "FAIL: '$ID' has no binary in tiers.yaml." >&2
  exit 1
fi

if [[ "$PROVISIONAL" != "true" ]]; then
  if [[ "$ship" != "true" ]]; then
    echo "FAIL: '$ID' is not shippable (tier=$tier). Use --provisional for red candidates." >&2
    exit 1
  fi
fi

echo "== smoke $IMAGE id=$ID binary=$binary tier=$tier provisional=$PROVISIONAL =="

if ! "$RUNTIME" run --rm --network=none --entrypoint bash "$IMAGE" -lc "command -v $binary >/dev/null"; then
  echo "FAIL: $binary not found in $IMAGE" >&2
  exit 1
fi

# Version-only (or binary-present) for servers that hang on bare initialize
case "$ID" in
  rust|c-cpp|lua|ruby)
    set +e
    ver="$("$RUNTIME" run --rm --network=none --entrypoint bash "$IMAGE" -lc \
      "$binary --version 2>&1 || $binary -v 2>&1 || true" | head -1)"
    set -e
    echo "OK $ID binary present (${ver:-no --version})"
    exit 0
    ;;
  java)
    # jdtls wrapper is python; --version starts the server — binary check is enough
    echo "OK $ID binary present"
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
