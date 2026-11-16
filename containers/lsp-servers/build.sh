#!/usr/bin/env bash
# Build per-language LSP images (shippable green/yellow only).
# Usage: ./build.sh <id|all>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PARSE=(python3 "$SCRIPT_DIR/parse-tiers.py" "$SCRIPT_DIR/tiers.yaml")
USER_UID="$(id -u)"
USER_GID="$(id -g)"
FEDORA_VERSION="$("${PARSE[@]}" --query json | python3 -c 'import json,sys; print(json.load(sys.stdin)["fedora"])')"
WANT="${1:-}"

if [[ -z "$WANT" ]]; then
  echo "Usage: $0 <id|all>" >&2
  echo "Shippable: $("${PARSE[@]}" --query shippable | tr '\n' ' ')" >&2
  echo "Red (not built): $("${PARSE[@]}" --query red | tr '\n' ' ')" >&2
  exit 1
fi

shippable="$("${PARSE[@]}" --query shippable)"

build_one() {
  local id="$1"
  local tier
  tier="$("${PARSE[@]}" --query tier --id "$id")"
  local ship
  ship="$("${PARSE[@]}" --query ship --id "$id")"
  if [[ "$ship" != "true" ]] || [[ "$tier" != "green" && "$tier" != "yellow" ]]; then
    echo "error: refusing to build '$id' (tier=$tier ship=$ship). Promote red→yellow first." >&2
    exit 1
  fi
  local image="lsp-${id}"
  echo "Building ${image}:latest (Fedora ${FEDORA_VERSION}, tier=${tier})..."
  podman build \
    --target "$id" \
    --build-arg FEDORA_VERSION="${FEDORA_VERSION}" \
    --build-arg USER_UID="${USER_UID}" \
    --build-arg USER_GID="${USER_GID}" \
    -t "${image}:latest" \
    -f Containerfile \
    .
  echo "Built ${image}:latest"
}

if [[ "$WANT" == "all" ]]; then
  while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    build_one "$id"
  done <<<"$shippable"
else
  build_one "$WANT"
fi

echo ""
echo "Smoke: ./smoke-lsp.sh lsp-<id>:latest <id>"
echo "Promote red: ./promote-check.sh <id>"
