#!/usr/bin/env bash
# Apply red → yellow edits for one language and sync status surfaces:
#   tiers.yaml, Containerfile label, build-lsp-<id>.yml mode, README tables.
# Does not commit or open a PR — CI does that after promote-check passes.
#
# Usage: ./apply-promote.sh <id>
# Exit 0 if edits applied (or already yellow/ship with status synced).
# Exit 2 if id is not a promotable red candidate / already-yellow language.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$SCRIPT_DIR"
PARSE=(python3 "$SCRIPT_DIR/parse-tiers.py" "$SCRIPT_DIR/tiers.yaml")

ID="${1:?usage: $0 <id>}"

tier="$("${PARSE[@]}" --query tier --id "$ID")"
ship="$("${PARSE[@]}" --query ship --id "$ID")"

already_yellow=false
if [[ "$tier" == "yellow" && "$ship" == "true" ]]; then
  already_yellow=true
elif [[ "$tier" != "red" ]]; then
  echo "FAIL: $ID tier=$tier — apply-promote only for red candidates." >&2
  exit 2
fi

if [[ "$already_yellow" != "true" ]]; then
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
else
  echo "OK $ID already yellow/ship — syncing status surfaces."
fi

# Sync build workflow mode + README status tables for this promotion.
python3 - "$REPO_ROOT" "$ID" <<'PY'
import re
import runpy
import sys
from pathlib import Path

repo_root = Path(sys.argv[1])
lang_id = sys.argv[2]
script_dir = repo_root / "containers" / "lsp-servers"
parse_tiers = runpy.run_path(str(script_dir / "parse-tiers.py"))["parse_tiers"]

REPO = "dsedgmen/devenv-packager"

# Human blurbs for lsp-servers README pin tables (keyed by language id).
PIN_BLURB = {
    "javascript": "npm `typescript-language-server` + `typescript`",
    "typescript": "npm `typescript-language-server` + `typescript`",
    "json": "npm `vscode-langservers-extracted`",
    "html": "npm `vscode-langservers-extracted`",
    "css": "npm `vscode-langservers-extracted`",
    "yaml": "npm `yaml-language-server`",
    "lua": "GitHub LuaLS release tarball",
    "java": "Eclipse JDT LS milestone + Fedora JRE",
    "ruby": "gem `ruby-lsp`",
}


def badge(workflow: str, alt: str) -> str:
    return f"![{alt}](https://github.com/{REPO}/actions/workflows/{workflow}/badge.svg)"


def status_row(lang: dict) -> str:
    tid = lang["id"]
    tier = lang["tier"]
    tag = "latest" if tier in ("green", "yellow") else "candidate"
    build = badge(f"build-lsp-{tid}.yml", f"lsp-{tid}")
    promote = (
        badge(f"promote-lsp-{tid}.yml", f"promote-{tid}") if tier == "red" else "—"
    )
    return f"| {tid} | {tier} | `lsp-{tid}:{tag}` | {build} | {promote} |"


def replace_pipe_table(text: str, header: str, separator: str, new_table: str) -> str:
    """Replace a markdown pipe table identified by header+separator lines.

    Only consumes consecutive `|...` rows (line-oriented), so later sections survive.
    """
    start = text.find(header)
    if start < 0:
        raise SystemExit(f"FAIL: table header not found: {header!r}")
    if not text.startswith(header + separator, start):
        raise SystemExit(f"FAIL: table separator not adjacent to header: {header!r}")
    body_start = start + len(header) + len(separator)
    body_end = body_start
    while body_end < len(text) and text.startswith("|", body_end):
        nl = text.find("\n", body_end)
        if nl < 0:
            body_end = len(text)
            break
        body_end = nl + 1
    return text[:start] + new_table + text[body_end:]


# --- build-lsp-<id>.yml: mode candidate → ship ---
wf = repo_root / ".github" / "workflows" / f"build-lsp-{lang_id}.yml"
if not wf.is_file():
    raise SystemExit(f"FAIL: missing workflow {wf}")
wf_text = wf.read_text(encoding="utf-8")
new_wf, n = re.subn(
    r"(?m)^(\s*mode:\s*)candidate\s*$",
    r"\1ship",
    wf_text,
    count=1,
)
if n == 1:
    wf.write_text(new_wf, encoding="utf-8")
    print(f"Updated {wf.relative_to(repo_root)}: mode → ship")
elif re.search(r"(?m)^\s*mode:\s*ship\s*$", wf_text):
    print(f"OK {wf.relative_to(repo_root)} already mode: ship")
else:
    raise SystemExit(f"FAIL: could not set mode: ship in {wf}")

data = parse_tiers(script_dir / "tiers.yaml")
langs = data["languages"]

# --- root README.md status table ---
readme = repo_root / "README.md"
readme_text = readme.read_text(encoding="utf-8")
status_header = "| Language | Category | Image | Build | Promote |\n"
status_sep = "|----------|----------|-------|-------|---------|\n"
status_table = status_header + status_sep + "\n".join(status_row(L) for L in langs) + "\n"
readme.write_text(
    replace_pipe_table(readme_text, status_header, status_sep, status_table),
    encoding="utf-8",
)
print("Updated README.md: LSP CI status table")

# --- containers/lsp-servers/README.md yellow + red pin tables ---
lsp_readme = script_dir / "README.md"
lsp_text = lsp_readme.read_text(encoding="utf-8")

yellow = [L for L in langs if L.get("tier") == "yellow"]
red = [L for L in langs if L.get("tier") == "red"]

yellow_section = "## Yellow (promoted non-RPM)\n\n"
if yellow:
    yellow_section += (
        "| id | Image | Pin source |\n"
        "|----|-------|------------|\n"
    )
    for L in yellow:
        blurb = PIN_BLURB.get(L["id"], L.get("planned_source") or L.get("pin") or "—")
        yellow_section += f"| `{L['id']}` | `lsp-{L['id']}` | {blurb} |\n"
    yellow_section += "\n"
else:
    yellow_section += "_None yet._\n\n"

groups: list[tuple[str, list[str]]] = []
seen: dict[str, int] = {}
for L in red:
    blurb = PIN_BLURB.get(L["id"], L.get("planned_source") or L.get("pin") or "—")
    if blurb not in seen:
        seen[blurb] = len(groups)
        groups.append((blurb, [L["id"]]))
    else:
        groups[seen[blurb]][1].append(L["id"])

red_table = "| id | Pin source |\n|----|------------|\n"
for blurb, ids in groups:
    id_cell = " / ".join(f"`{i}`" for i in ids)
    red_table += f"| {id_cell} | {blurb} |\n"

if "## Yellow (promoted non-RPM)" in lsp_text:
    # Replace through the next ## heading (exclusive).
    lsp_text = re.sub(
        r"## Yellow \(promoted non-RPM\)\n(?:.*\n)*?(?=\n## )",
        yellow_section.rstrip() + "\n",
        lsp_text,
        count=1,
    )
else:
    lsp_text = lsp_text.replace(
        "## Red candidates → yellow promotion\n",
        yellow_section + "## Red candidates → yellow promotion\n",
        1,
    )

red_header = "| id | Pin source |\n"
red_sep = "|----|------------|\n"
# Prefer the table under Red candidates (first pin-source table after that heading).
red_heading = "## Red candidates → yellow promotion\n"
red_at = lsp_text.find(red_heading)
if red_at < 0:
    raise SystemExit("FAIL: red candidates heading missing")
table_at = lsp_text.find(red_header, red_at)
if table_at < 0:
    raise SystemExit("FAIL: red candidates table header missing")
# replace_pipe_table searches from start; slice to keep the first match under Red.
prefix = lsp_text[:table_at]
suffix = replace_pipe_table(lsp_text[table_at:], red_header, red_sep, red_table)
lsp_text = prefix + suffix

# Document that apply-promote syncs status surfaces (idempotent note near step 3).
note = (
    "Local step 3: `./apply-promote.sh <id>` then open the PR yourself. That script also flips\n"
    "`build-lsp-<id>.yml` to `mode: ship` and refreshes README status tables.\n"
)
old_note = "Local step 3: `./apply-promote.sh <id>` then open the PR yourself.\n"
if note not in lsp_text:
    if old_note in lsp_text:
        lsp_text = lsp_text.replace(old_note, note, 1)
    elif "refreshes README status tables" not in lsp_text:
        raise SystemExit("FAIL: could not update apply-promote local step note")

lsp_readme.write_text(lsp_text, encoding="utf-8")
print("Updated containers/lsp-servers/README.md: yellow/red status tables")
PY

echo "OK apply-promote $ID"
