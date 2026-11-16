#!/usr/bin/env bash
# Build Flatpak packages for Vim and Neovim
# Requires sibling devenv-ai-assistant + devenv-ai-helper (see ../scripts/prepare-build-context.sh)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "═══════════════════════════════════════════════════════════"
echo "  Flatpak Builder for Vim AI Assistant"
echo "═══════════════════════════════════════════════════════════"
echo ""

echo "Preparing build context from sibling repos..."
"$REPO_ROOT/scripts/prepare-build-context.sh"

# Check dependencies
if ! command -v flatpak-builder &> /dev/null; then
    echo "flatpak-builder not found"
    echo "Install with: sudo dnf install flatpak-builder"
    exit 1
fi

# Add Fedora Flatpak remote (org.fedoraproject.Platform/Sdk)
if ! flatpak remotes | grep -qE "(^|\s)fedora(\s|$)"; then
    echo "Adding Fedora Flatpak remote..."
    flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org
fi

# Add Flathub if not already added
if ! flatpak remotes | grep -q flathub; then
    echo "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Install required runtimes
echo "Installing Flatpak runtimes..."
flatpak install -y fedora org.fedoraproject.Platform//f45 org.fedoraproject.Sdk//f45

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Building Neovim Flatpak"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Build Neovim
flatpak-builder --force-clean --repo=repo build-neovim org.devenv.Neovim.yaml

echo ""
echo "✅ Neovim Flatpak built!"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "  Building Vim Flatpak"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Build Vim
flatpak-builder --force-clean --repo=repo build-vim org.devenv.Vim.yaml

echo ""
echo "✅ Vim Flatpak built!"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "  Building Extensions (LSP & Tree-sitter)"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Build Python LSP extension
flatpak-builder --force-clean --repo=repo build-ext-pylsp extensions/org.devenv.Neovim.LSP.Python.yaml

# Build Tree-sitter Python extension
flatpak-builder --force-clean --repo=repo build-ext-ts-python extensions/org.devenv.Neovim.TreeSitter.Python.yaml

echo ""
echo "✅ Extensions built!"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "  Installation"
echo "═══════════════════════════════════════════════════════════"
echo ""

echo "Install locally:"
echo "  flatpak --user remote-add --no-gpg-verify devenv-packager-repo repo"
echo "  flatpak --user install devenv-packager-repo org.devenv.Neovim"
echo "  flatpak --user install devenv-packager-repo org.devenv.Vim"
echo ""
echo "Install extensions:"
echo "  flatpak --user install devenv-packager-repo org.devenv.Neovim.LSP.Python"
echo "  flatpak --user install devenv-packager-repo org.devenv.Neovim.TreeSitter.Python"
echo ""
echo "Run:"
echo "  flatpak run org.devenv.Neovim"
echo "  flatpak run org.devenv.Vim"
echo ""
echo "Flatpaks built successfully! 📦"
echo ""
