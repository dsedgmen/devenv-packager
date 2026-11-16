#!/usr/bin/env bash
# Host editor → per-language LSP container over stdio (JSON-RPC).
# Maps language alias → lsp-<id>:latest (override with LSP_IMAGE).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSE=(python3 "$SCRIPT_DIR/parse-tiers.py" "$SCRIPT_DIR/tiers.yaml")

LSP_LANG="${1:-}"
if [[ -z "$LSP_LANG" ]]; then
  echo "Usage: $0 <language>" >&2
  echo "Shippable aliases from tiers.yaml (green/yellow only)." >&2
  exit 1
fi
shift || true

ID=""
# Resolve alias → id
while IFS= read -r cand; do
  [[ -z "$cand" ]] && continue
  while IFS= read -r alias; do
    if [[ "$alias" == "$LSP_LANG" ]]; then
      ID="$cand"
      break 2
    fi
  done < <("${PARSE[@]}" --query aliases --id "$cand")
done < <("${PARSE[@]}" --query shippable)

if [[ -z "$ID" ]]; then
  # Also try direct id among all langs for clearer errors
  if "${PARSE[@]}" --query tier --id "$LSP_LANG" >/dev/null 2>&1; then
    tier="$("${PARSE[@]}" --query tier --id "$LSP_LANG")"
    echo "error: language '$LSP_LANG' is tier=$tier and not shipped" >&2
    echo "Promote red→yellow via ./promote-check.sh before use." >&2
  else
    echo "error: unknown language '$LSP_LANG'" >&2
  fi
  exit 1
fi

LSP_IMAGE="${LSP_IMAGE:-lsp-${ID}:latest}"
RUNTIME="${CONTAINER_RUNTIME:-}"
if [[ -z "$RUNTIME" ]]; then
  if command -v podman >/dev/null 2>&1; then
    RUNTIME=podman
  elif command -v docker >/dev/null 2>&1; then
    RUNTIME=docker
  else
    echo "error: need podman or docker to run $LSP_IMAGE" >&2
    exit 1
  fi
fi

WORKSPACE="${LSP_WORKSPACE:-$(pwd)}"

exec "$RUNTIME" run --rm -i \
  --network=none \
  --userns=keep-id \
  -v "${WORKSPACE}:/workspace:z" \
  -w /workspace \
  "$LSP_IMAGE" \
  "$@"
