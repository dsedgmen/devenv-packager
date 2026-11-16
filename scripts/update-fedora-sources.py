#!/usr/bin/env python3
"""Refresh Flatpak lookaside pins and Fedora base version from dist-git.

Updates:
  - flatpak/fedora-sources.json
  - flatpak/FEDORA_VERSION
  - flatpak/**/*.yaml (runtime/sdk/version + lookaside url/sha256)
  - flatpak/build-flatpak.sh
  - containers/**/Containerfile and related Fedora version mentions
  - .github/workflows that pin registry.fedoraproject.org/fedora:N

Prints fedora=<N> and CHANGED=yes|no for CI.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FLATPAK = ROOT / "flatpak"
SOURCES = FLATPAK / "fedora-sources.json"
VERSION_FILE = FLATPAK / "FEDORA_VERSION"
DISTGIT_SOURCES = "https://src.fedoraproject.org/rpms/{pkg}/raw/f{ver}/f/sources"
LOOKASIDE_SHA512 = (
    "https://src.fedoraproject.org/repo/pkgs/{pkg}/{filename}/sha512/{digest}/{filename}"
)
LOOKASIDE_MD5 = (
    "https://src.fedoraproject.org/repo/pkgs/{pkg}/{filename}/md5/{digest}/{filename}"
)


def http_get(url: str, timeout: int = 120) -> bytes:
    req = urllib.request.Request(
        url, headers={"User-Agent": "devenv-packager-updater/1.0"}
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read()


def http_ok(url: str, timeout: int = 30) -> bool:
    try:
        http_get(url, timeout=timeout)
        return True
    except (urllib.error.HTTPError, urllib.error.URLError):
        return False


def parse_sources_file(text: str) -> list[dict]:
    files: list[dict] = []
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        m = re.match(r"^SHA512 \((.+)\) = ([0-9a-fA-F]+)$", line)
        if m:
            files.append({"filename": m.group(1), "sha512": m.group(2).lower()})
            continue
        m = re.match(r"^([0-9a-fA-F]{32})\s+(\S+)$", line)
        if m:
            files.append({"filename": m.group(2), "md5": m.group(1).lower()})
    return files


def lookaside_url(pkg: str, entry: dict) -> str:
    if "sha512" in entry:
        return LOOKASIDE_SHA512.format(
            pkg=pkg, filename=entry["filename"], digest=entry["sha512"]
        )
    if "md5" in entry:
        return LOOKASIDE_MD5.format(
            pkg=pkg, filename=entry["filename"], digest=entry["md5"]
        )
    raise ValueError(f"no digest for {pkg} {entry}")


def fetch_sha256(url: str) -> str:
    return hashlib.sha256(http_get(url, timeout=300)).hexdigest()


def detect_fedora_version(current: int, check_newer: bool) -> int:
    if not check_newer:
        return current
    newer = current + 1
    if http_ok(DISTGIT_SOURCES.format(pkg="neovim", ver=newer)):
        return newer
    return current


def select_files(distgit: str, parsed: list[dict], tracked: set[str]) -> list[dict]:
    matched = [p for p in parsed if p["filename"] in tracked]
    if matched:
        return matched
    if distgit == "neovim":
        return [
            p
            for p in parsed
            if p["filename"].startswith("neovim-") and p["filename"].endswith(".tar.gz")
        ]
    if distgit == "python-jedi":
        return [p for p in parsed if p["filename"].startswith("jedi-")]
    # Skip detached signatures and other non-source artifacts
    return [p for p in parsed if not p["filename"].endswith(".sign")]


def refresh_packages(data: dict, fedora: int) -> dict:
    for _name, meta in data["packages"].items():
        distgit = meta["distgit"]
        text = http_get(DISTGIT_SOURCES.format(pkg=distgit, ver=fedora)).decode()
        parsed = parse_sources_file(text)
        if not parsed:
            raise RuntimeError(f"no sources parsed for {distgit} f{fedora}")
        tracked = {f["filename"] for f in meta.get("files", [])}
        chosen = select_files(distgit, parsed, tracked)
        new_files = []
        for p in chosen:
            url = lookaside_url(distgit, p)
            entry = {
                "filename": p["filename"],
                "sha256": fetch_sha256(url),
            }
            if "sha512" in p:
                entry["sha512"] = p["sha512"]
            if "md5" in p:
                entry["md5"] = p["md5"]
            new_files.append(entry)
        meta["files"] = new_files
    data["fedora"] = fedora
    data["runtime"] = "org.fedoraproject.Platform"
    data["sdk"] = "org.fedoraproject.Sdk"
    data["runtime_repo"] = "oci+https://registry.fedoraproject.org"
    return data


def apply_to_tree(data: dict) -> None:
    fedora = int(data["fedora"])
    branch = f"f{fedora}"
    runtime = data["runtime"]
    sdk = data["sdk"]

    VERSION_FILE.write_text(f"{fedora}\n")

    for path in FLATPAK.rglob("*.yaml"):
        text = path.read_text()
        text = re.sub(r"(?m)^runtime:\s*.*$", f"runtime: {runtime}", text)
        text = re.sub(r"(?m)^sdk:\s*.*$", f"sdk: {sdk}", text)
        text = re.sub(r"(?m)^runtime-version:\s*.*$", f"runtime-version: {branch}", text)
        text = re.sub(r"\bFedora f\d+\b", f"Fedora {branch}", text)
        text = re.sub(r"\bf\d+ lookaside\b", f"{branch} lookaside", text)

        for meta in data["packages"].values():
            distgit = meta["distgit"]
            for entry in meta["files"]:
                filename = entry["filename"]
                url = lookaside_url(distgit, entry)
                # Match any lookaside URL for this package that ends with this filename
                # (avoids clobbering sibling archives like neovim + neovim-vendor).
                text = re.sub(
                    rf"https://src\.fedoraproject\.org/repo/pkgs/{re.escape(distgit)}/\S+/{re.escape(filename)}",
                    url,
                    text,
                )
                text = re.sub(
                    rf"(url:\s*{re.escape(url)}\s*\n\s*sha256:\s*)[0-9a-fA-F]+",
                    rf"\g<1>{entry['sha256']}",
                    text,
                )
        path.write_text(text)

    build_sh = FLATPAK / "build-flatpak.sh"
    if build_sh.exists():
        text = build_sh.read_text()
        if "remote-add --if-not-exists fedora" not in text:
            text = text.replace(
                "# Add Flathub if not already added",
                "# Add Fedora Flatpak remote (org.fedoraproject.Platform/Sdk)\n"
                'if ! flatpak remotes | grep -qE "(^|\\s)fedora(\\s|$)"; then\n'
                "    echo \"Adding Fedora Flatpak remote...\"\n"
                "    flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org\n"
                "fi\n\n"
                "# Add Flathub if not already added",
            )
        text = re.sub(
            r"flatpak install -y[^\n]*",
            f"flatpak install -y fedora {runtime}//{branch} {sdk}//{branch}",
            text,
        )
        build_sh.write_text(text)

    for path in (ROOT / "containers").rglob("*"):
        if path.name != "Containerfile" and path.suffix != ".md":
            continue
        text = path.read_text()
        text = re.sub(
            r"registry\.fedoraproject\.org/fedora:\d+",
            f"registry.fedoraproject.org/fedora:{fedora}",
            text,
        )
        text = re.sub(r"(Based on Fedora )\d+", rf"\g<1>{fedora}", text)
        text = re.sub(r"(Fedora )\d+( repos)", rf"\g<1>{fedora}\2", text)
        text = re.sub(r"(Version pinned \(Fedora )\d+(\))", rf"\g<1>{fedora}\2", text)
        text = re.sub(r"(Version locked \(Fedora )\d+(\))", rf"\g<1>{fedora}\2", text)
        path.write_text(text)

    for wf in (ROOT / ".github" / "workflows").glob("*.yml"):
        text = wf.read_text()
        text = re.sub(
            r"image:\s*\S*flatpak-github-actions:freedesktop-\S+",
            f"image: registry.fedoraproject.org/fedora:{fedora}",
            text,
        )
        text = re.sub(
            r"image:\s*registry\.fedoraproject\.org/fedora:\d+",
            f"image: registry.fedoraproject.org/fedora:{fedora}",
            text,
        )
        wf.write_text(text)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check-newer-fedora",
        action="store_true",
        help="Bump when f{N+1} dist-git exists for neovim",
    )
    parser.add_argument("--fedora", type=int, default=None)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    old_sources = SOURCES.read_text()
    data = json.loads(old_sources)
    current = int(
        VERSION_FILE.read_text().strip() if VERSION_FILE.exists() else data["fedora"]
    )
    fedora = args.fedora or detect_fedora_version(current, args.check_newer_fedora)
    data = refresh_packages(data, fedora)
    new_sources = json.dumps(data, indent=2) + "\n"
    changed = new_sources != old_sources or fedora != current

    if args.dry_run:
        print(f"fedora={fedora}")
        print(f"CHANGED={'yes' if changed else 'no'}")
        return 0

    SOURCES.write_text(new_sources)
    apply_to_tree(data)
    print(f"fedora={fedora}")
    print(f"CHANGED={'yes' if changed else 'no'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
