#!/usr/bin/env bash
# Red → yellow promotion gate: pin fields + build + smoke + Trivy.
# Does not rewrite tiers.yaml; exit 0 means the PR may set tier:yellow ship:true.
#
# Usage: ./promote-check.sh <id>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
PARSE=(python3 "$SCRIPT_DIR/parse-tiers.py" "$SCRIPT_DIR/tiers.yaml")

ID="${1:?usage: $0 <id>}"

tier="$("${PARSE[@]}" --query tier --id "$ID")"
ship="$("${PARSE[@]}" --query ship --id "$ID")"
pin="$("${PARSE[@]}" --query pin --id "$ID")"
binary="$("${PARSE[@]}" --query binary --id "$ID")"

echo "== promote-check $ID (tier=$tier ship=$ship) =="

if [[ "$tier" == "green" ]]; then
  echo "OK $ID is green (Fedora RPM) — no promotion needed."
  exit 0
fi

if [[ "$tier" == "yellow" && "$ship" == "true" ]]; then
  echo "OK $ID already yellow/shippable — re-running build+smoke+trivy."
fi

if [[ "$tier" == "red" ]]; then
  if [[ -z "$pin" ]]; then
    echo "FAIL: $ID is red with pin: null." >&2
    echo "Add a pin (version/url/checksum) and Containerfile target AS $ID, then re-run." >&2
    exit 1
  fi
  if [[ -z "$binary" ]]; then
    echo "FAIL: $ID is red with binary: null — set command/binary for the pinned LSP." >&2
    exit 1
  fi
  echo "Pin present for red candidate $ID — attempting provisional build (target must exist)."
fi

RUNTIME=podman
command -v podman >/dev/null 2>&1 || RUNTIME=docker

USER_UID="$(id -u)"
USER_GID="$(id -g)"
FEDORA_VERSION="$("${PARSE[@]}" --query json | python3 -c 'import json,sys; print(json.load(sys.stdin)["fedora"])')"
IMAGE="lsp-${ID}:promote"

echo "-- build target $ID --"
if ! $RUNTIME build \
  --target "$ID" \
  --build-arg FEDORA_VERSION="${FEDORA_VERSION}" \
  --build-arg USER_UID="${USER_UID}" \
  --build-arg USER_GID="${USER_GID}" \
  -t "$IMAGE" \
  -f Containerfile \
  .; then
  echo "FAIL: Containerfile has no working target '$ID' (add yellow install stage first)." >&2
  exit 1
fi

echo "-- smoke --"
chmod +x "$SCRIPT_DIR/smoke-lsp.sh"
if [[ "$ship" == "true" ]]; then
  "$SCRIPT_DIR/smoke-lsp.sh" "$IMAGE" "$ID"
else
  "$SCRIPT_DIR/smoke-lsp.sh" --provisional "$IMAGE" "$ID"
fi

echo "-- trivy --"
if ! command -v trivy >/dev/null 2>&1; then
  echo "WARN: trivy not installed locally; CI will enforce Trivy. Install: https://aquasecurity.github.io/trivy/" >&2
  echo "Local promote-check incomplete without trivy." >&2
  exit 1
fi
trivy image --scanners vuln,secret,misconfig --severity HIGH,CRITICAL --exit-code 1 "$IMAGE"

echo ""
echo "PASS promote-check for $ID."
echo "In the same PR: set tier: yellow, ship: true in tiers.yaml (and keep Containerfile target)."
