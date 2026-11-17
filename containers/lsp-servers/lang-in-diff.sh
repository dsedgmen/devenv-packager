#!/usr/bin/env bash
# Exit 0 if language <id> is affected by the git diff; exit 1 if not.
# Usage: lang-in-diff.sh <id> [base_ref] [head_ref]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

ID="${1:?usage: $0 <id> [base] [head]}"
BASE="${2:-}"
HEAD="${3:-HEAD}"

if [[ -z "$BASE" ]]; then
  if git rev-parse --verify origin/main >/dev/null 2>&1; then
    BASE="origin/main"
  else
    echo "affected $ID (no base ref)"
    exit 0
  fi
fi

if ! git rev-parse --verify "$BASE" >/dev/null 2>&1; then
  echo "affected $ID (base missing)"
  exit 0
fi

RANGE="${BASE}...${HEAD}"

changed="$(git diff --name-only "$RANGE" -- \
  containers/lsp-servers/Containerfile \
  containers/lsp-servers/tiers.yaml \
  containers/lsp-servers/smoke-lsp.sh \
  containers/lsp-servers/build.sh \
  containers/lsp-servers/lang-in-diff.sh \
  flatpak/FEDORA_VERSION \
  .github/workflows/_reusable-build-lsp.yml \
  .github/workflows/lsp-dispatch.yml \
  ".github/workflows/build-lsp-${ID}.yml" \
  2>/dev/null || true)"

if [[ -z "$changed" ]]; then
  echo "skip $ID (no relevant files)"
  exit 1
fi

if echo "$changed" | grep -qE 'smoke-lsp\.sh$|build\.sh$|lang-in-diff\.sh$|FEDORA_VERSION$|_reusable-build-lsp\.yml$|lsp-dispatch\.yml$'; then
  echo "affected $ID (shared build infra)"
  exit 0
fi

if echo "$changed" | grep -qE "build-lsp-${ID}\\.yml$"; then
  echo "affected $ID (own workflow)"
  exit 0
fi

if echo "$changed" | grep -q 'tiers\.yaml$'; then
  diff_tiers="$(git diff "$RANGE" -- containers/lsp-servers/tiers.yaml || true)"
  if ID="$ID" python3 -c '
import os, re, sys
lang = os.environ["ID"]
text = sys.stdin.read()
cur = None
for line in text.splitlines():
    m = re.match(r"^[-+ ]\s+- id:\s*(\S+)", line)
    if m:
        cur = m.group(1)
        continue
    if cur == lang and line[:1] in "+-" and not line.startswith(("+++", "---")):
        sys.exit(0)
sys.exit(1)
' <<<"$diff_tiers"; then
    echo "affected $ID (tiers.yaml)"
    exit 0
  fi
fi

if echo "$changed" | grep -q 'Containerfile$'; then
  diff_cf="$(git diff "$RANGE" -- containers/lsp-servers/Containerfile || true)"
  if ID="$ID" python3 -c '
import os, re, sys
lang = os.environ["ID"]
diff = sys.stdin.read()
if re.search(rf"\bAS\s+{re.escape(lang)}\b", diff):
    sys.exit(0)
if re.search(rf"org\.devenv\.lsp\.id=\"{re.escape(lang)}\"", diff):
    sys.exit(0)
uses_npm = lang in {
    "javascript", "typescript", "json", "yaml", "html", "css", "bash",
}
if re.search(r"\bAS\s+base\b", diff):
    sys.exit(0)
if uses_npm and re.search(r"\bAS\s+npm-base\b", diff):
    sys.exit(0)
sys.exit(1)
' <<<"$diff_cf"; then
    echo "affected $ID (Containerfile)"
    exit 0
  fi
fi

echo "skip $ID"
exit 1
