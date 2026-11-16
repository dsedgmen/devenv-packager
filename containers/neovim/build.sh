#!/usr/bin/env bash
# Build Neovim container from Fedora + dsedgmen/devenv COPR (no staged configs).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FEDORA_VERSION="${FEDORA_VERSION:-$(tr -d '[:space:]' < "$REPO_ROOT/flatpak/FEDORA_VERSION" 2>/dev/null || echo 45)}"
REGISTRY="${DEVENV_PACKAGER_REGISTRY:-ghcr.io/dsedgmen/devenv-packager}"

USER_UID="$(id -u)"
USER_GID="$(id -g)"
USERNAME="${USERNAME:-vimuser}"

echo "Building ${REGISTRY}/neovim:latest (Fedora ${FEDORA_VERSION})..."
podman build \
    --build-arg FEDORA_VERSION="${FEDORA_VERSION}" \
    --build-arg USER_UID="${USER_UID}" \
    --build-arg USER_GID="${USER_GID}" \
    --build-arg USERNAME="${USERNAME}" \
    -t "${REGISTRY}/neovim:latest" \
    -t neovim:latest \
    -f "$SCRIPT_DIR/Containerfile" \
    "$SCRIPT_DIR"

echo "Built ${REGISTRY}/neovim:latest"
