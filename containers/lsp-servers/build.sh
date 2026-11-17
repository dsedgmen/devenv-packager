#!/usr/bin/env bash
# Build per-language LSP images.
# Usage: ./build.sh <id|all|candidates>
#   all         — shippable green/yellow → lsp-<id>:latest
#   candidates  — all red → lsp-<id>:candidate
#   <id>        — one language (ship → :latest, red → :candidate)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PARSE=(python3 "$SCRIPT_DIR/parse-tiers.py" "$SCRIPT_DIR/tiers.yaml")
USER_UID="$(id -u)"
USER_GID="$(id -g)"
FEDORA_VERSION="$("${PARSE[@]}" --query json | python3 -c 'import json,sys; print(json.load(sys.stdin)["fedora"])')"
WANT="${1:-}"

RUNTIME=podman
command -v podman >/dev/null 2>&1 || RUNTIME=docker

if [[ -z "$WANT" ]]; then
  echo "Usage: $0 <id|all|candidates>" >&2
  echo "Shippable: $("${PARSE[@]}" --query shippable | tr '\n' ' ')" >&2
  echo "Red candidates: $("${PARSE[@]}" --query red | tr '\n' ' ')" >&2
  exit 1
fi

build_one() {
  local id="$1"
  local tier ship tag image
  tier="$("${PARSE[@]}" --query tier --id "$id")"
  ship="$("${PARSE[@]}" --query ship --id "$id")"
  image="lsp-${id}"

  if [[ "$tier" == "red" ]]; then
    tag="candidate"
  elif [[ "$ship" == "true" ]] && [[ "$tier" == "green" || "$tier" == "yellow" ]]; then
    tag="latest"
  else
    echo "error: refusing to build '$id' (tier=$tier ship=$ship)." >&2
    exit 1
  fi

  echo "Building ${image}:${tag} (Fedora ${FEDORA_VERSION}, tier=${tier})..."
  $RUNTIME build \
    --target "$id" \
    --build-arg FEDORA_VERSION="${FEDORA_VERSION}" \
    --build-arg USER_UID="${USER_UID}" \
    --build-arg USER_GID="${USER_GID}" \
    -t "${image}:${tag}" \
    -f Containerfile \
    .
  echo "Built ${image}:${tag}"
}

if [[ "$WANT" == "all" ]]; then
  while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    build_one "$id"
  done < <("${PARSE[@]}" --query shippable)
elif [[ "$WANT" == "candidates" ]]; then
  while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    build_one "$id"
  done < <("${PARSE[@]}" --query red)
else
  build_one "$WANT"
fi

echo ""
echo "Smoke shippable: ./smoke-lsp.sh lsp-<id>:latest <id>"
echo "Smoke candidate: ./smoke-lsp.sh --provisional lsp-<id>:candidate <id>"
echo "Promote red: ./promote-check.sh <id>"
