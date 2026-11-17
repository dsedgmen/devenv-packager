#!/usr/bin/env bash
# Apply red → yellow edits for one language (tiers.yaml + Containerfile label).
# Does not commit or open a PR — CI does that after promote-check passes.
#
# Usage: ./apply-promote.sh <id>
# Exit 0 if edits applied (or already yellow/ship).
# Exit 2 if id is not a promotable red candidate.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
PARSE=(python3 "$SCRIPT_DIR/parse-tiers.py" "$SCRIPT_DIR/tiers.yaml")

ID="${1:?usage: $0 <id>}"

tier="$("${PARSE[@]}" --query tier --id "$ID")"
ship="$("${PARSE[@]}" --query ship --id "$ID")"

if [[ "$tier" == "yellow" && "$ship" == "true" ]]; then
  echo "OK $ID already yellow/ship — nothing to apply."
  exit 0
fi

if [[ "$tier" != "red" ]]; then
  echo "FAIL: $ID tier=$tier — apply-promote only for red candidates." >&2
  exit 2
fi

pin="$("${PARSE[@]}" --query pin --id "$ID")"
binary="$("${PARSE[@]}" --query binary --id "$ID")"
if [[ -z "$pin" || -z "$binary" ]]; then
  echo "FAIL: $ID missing pin or binary." >&2
  exit 2
fi

python3 - "$ID" <<'PY'
import sys
from pathlib import Path

lang_id = sys.argv[1]
tiers = Path("tiers.yaml")
lines = tiers.read_text(encoding="utf-8").splitlines(keepends=True)
out: list[str] = []
in_block = False
changed_tier = changed_ship = False

for line in lines:
    stripped = line.split("#", 1)[0].rstrip()
    if stripped.lstrip().startswith("- id:"):
        cur = stripped.split(":", 1)[1].strip()
        in_block = cur == lang_id
        out.append(line)
        continue
    if in_block:
        key = stripped.lstrip()
        if key.startswith("tier:"):
            indent = line[: len(line) - len(line.lstrip())]
            out.append(f"{indent}tier: yellow\n")
            changed_tier = True
            continue
        if key.startswith("ship:"):
            indent = line[: len(line) - len(line.lstrip())]
            out.append(f"{indent}ship: true\n")
            changed_ship = True
            continue
    out.append(line)

if not changed_tier or not changed_ship:
    raise SystemExit(f"FAIL: could not update tier/ship for {lang_id}")
tiers.write_text("".join(out), encoding="utf-8")
print(f"Updated tiers.yaml: {lang_id} → tier=yellow ship=true")
PY

python3 - "$ID" <<'PY'
import re
import sys
from pathlib import Path

lang_id = sys.argv[1]
cf = Path("Containerfile")
text = cf.read_text(encoding="utf-8")
# Match the stage for this id, then flip the first tier label in that stage.
pattern = re.compile(
    rf'(FROM\s+\S+\s+AS\s+{re.escape(lang_id)}\b.*?'
    rf'LABEL\s+org\.devenv\.lsp\.tier=)"red"',
    re.DOTALL,
)
new, n = pattern.subn(r'\1"yellow"', text, count=1)
if n != 1:
    raise SystemExit(f"FAIL: could not set Containerfile tier label for AS {lang_id}")
cf.write_text(new, encoding="utf-8")
print(f'Updated Containerfile: AS {lang_id} tier label → yellow')
PY

echo "OK apply-promote $ID"
