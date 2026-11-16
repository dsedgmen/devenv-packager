#!/usr/bin/env python3
"""Parse tiers.yaml (constrained schema) without PyYAML."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def parse_tiers(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    fedora = 45
    langs: list[dict] = []
    cur: dict | None = None

    def flush() -> None:
        nonlocal cur
        if cur and "id" in cur:
            langs.append(cur)
        cur = None

    for raw in text.splitlines():
        line = raw.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        if line.startswith("fedora:"):
            fedora = int(line.split(":", 1)[1].strip())
            continue
        if line.startswith("languages:"):
            continue
        stripped = line.lstrip()
        indent = len(line) - len(stripped)
        if stripped.startswith("- id:"):
            flush()
            cur = {"id": stripped.split(":", 1)[1].strip()}
            continue
        if cur is None or indent < 2:
            continue
        if ":" not in stripped:
            continue
        key, val = stripped.split(":", 1)
        key = key.strip()
        val = val.strip()
        if val.startswith("[") and val.endswith("]"):
            inner = val[1:-1].strip()
            cur[key] = [p.strip() for p in inner.split(",") if p.strip()] if inner else []
        elif val in ("true", "false"):
            cur[key] = val == "true"
        elif val == "null" or val == "~" or val == "":
            cur[key] = None
        else:
            cur[key] = val
    flush()
    return {"fedora": fedora, "languages": langs}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("tiers", nargs="?", default=str(Path(__file__).with_name("tiers.yaml")))
    ap.add_argument(
        "--query",
        choices=(
            "shippable",
            "green",
            "yellow",
            "red",
            "ids",
            "json",
            "image",
            "binary",
            "aliases",
            "tier",
            "fedora_pkg",
            "ship",
            "pin",
        ),
        default="shippable",
    )
    ap.add_argument("--id", help="Language id for field queries")
    args = ap.parse_args()
    data = parse_tiers(Path(args.tiers))
    langs = data["languages"]

    def by_tier(t: str) -> list[dict]:
        return [L for L in langs if L.get("tier") == t]

    if args.query == "json":
        json.dump(data, sys.stdout, indent=2)
        sys.stdout.write("\n")
        return 0
    if args.query == "ids":
        print("\n".join(L["id"] for L in langs))
        return 0
    if args.query == "shippable":
        print("\n".join(L["id"] for L in langs if L.get("ship") and L.get("tier") in ("green", "yellow")))
        return 0
    if args.query in ("green", "yellow", "red"):
        print("\n".join(L["id"] for L in by_tier(args.query)))
        return 0

    if not args.id:
        print("error: --id required for this query", file=sys.stderr)
        return 2
    match = next((L for L in langs if L["id"] == args.id), None)
    if not match:
        # alias lookup
        for L in langs:
            aliases = L.get("aliases") or []
            if args.id in aliases or args.id == L["id"]:
                match = L
                break
    if not match:
        print(f"error: unknown language {args.id}", file=sys.stderr)
        return 1

    if args.query == "image":
        print(f"lsp-{match['id']}")
        return 0
    if args.query == "aliases":
        aliases = match.get("aliases") or [match["id"]]
        print("\n".join(aliases))
        return 0
    val = match.get(args.query)
    if isinstance(val, list):
        print(" ".join(str(x) for x in val))
    elif val is None:
        print("")
    elif isinstance(val, bool):
        print("true" if val else "false")
    else:
        print(val)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
