#!/usr/bin/env bash
# Stage editor configs + devenv-ai-helper + lsp-setup into build-context/
# for Flatpak manifests. Editor containers use COPR RPMs instead.
# Never copies from the builder's home configs as the source of truth.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTEXT_DIR="${BUILD_CONTEXT_DIR:-$REPO_ROOT/build-context}"

die() {
    echo "error: $*" >&2
    exit 1
}

resolve_assistant() {
    local dir="${DEVENV_AI_DIR:-${VIM_AI_DIR:-}}"
    if [ -z "$dir" ]; then
        for candidate in \
            "$REPO_ROOT/../devenv-ai-assistant" \
            "$REPO_ROOT/../vim-ai-assistant" \
            "$HOME/devenv-ai-assistant" \
            "$HOME/vim-ai-assistant" \
            "$REPO_ROOT/.deps/devenv-ai-assistant" \
            "$REPO_ROOT/.deps/vim-ai-assistant"; do
            if [ -f "$candidate/nvim-init.lua" ]; then
                dir="$(cd "$candidate" && pwd)"
                break
            fi
        done
    fi
    if [ -z "$dir" ] || [ ! -f "$dir/nvim-init.lua" ]; then
        die "devenv-ai-assistant not found. Set DEVENV_AI_DIR or clone sibling ../devenv-ai-assistant
  Expected: nvim-init.lua, vimrc"
    fi
    for f in nvim-init.lua vimrc; do
        [ -f "$dir/$f" ] || die "missing $dir/$f"
    done
    echo "$dir"
}

resolve_lsp_setup() {
    local dir="${DEVENV_LSP_SETUP_DIR:-}"
    if [ -z "$dir" ]; then
        for candidate in \
            "$REPO_ROOT/../devenv-lsp-setup" \
            "$HOME/devenv-lsp-setup" \
            "$REPO_ROOT/.deps/devenv-lsp-setup"; do
            if [ -f "$candidate/lsp-config.lua" ]; then
                dir="$(cd "$candidate" && pwd)"
                break
            fi
        done
    fi
    if [ -z "$dir" ] || [ ! -f "$dir/lsp-config.lua" ]; then
        die "devenv-lsp-setup not found. Set DEVENV_LSP_SETUP_DIR or clone sibling ../devenv-lsp-setup
  Expected: lsp-config.lua, treesitter-config.lua"
    fi
    for f in lsp-config.lua treesitter-config.lua; do
        [ -f "$dir/$f" ] || die "missing $dir/$f"
    done
    echo "$dir"
}

resolve_code_flowchart() {
    local dir="${DEVENV_CODE_FLOWCHART_DIR:-}"
    if [ -z "$dir" ]; then
        for candidate in \
            "$REPO_ROOT/../devenv-code-flowchart" \
            "$HOME/devenv-code-flowchart" \
            "$REPO_ROOT/.deps/devenv-code-flowchart"; do
            if [ -f "$candidate/code-flowchart.lua" ]; then
                dir="$(cd "$candidate" && pwd)"
                break
            fi
        done
    fi
    if [ -z "$dir" ] || [ ! -f "$dir/code-flowchart.lua" ]; then
        die "devenv-code-flowchart not found. Set DEVENV_CODE_FLOWCHART_DIR or clone sibling ../devenv-code-flowchart
  Expected: code-flowchart.lua"
    fi
    echo "$dir"
}

resolve_image_inspect() {
    local dir="${DEVENV_IMAGE_INSPECT_DIR:-}"
    if [ -z "$dir" ]; then
        for candidate in \
            "$REPO_ROOT/../devenv-image-inspect" \
            "$HOME/devenv-image-inspect" \
            "$REPO_ROOT/.deps/devenv-image-inspect"; do
            if [ -f "$candidate/bin/devenv-image-inspect" ]; then
                dir="$(cd "$candidate" && pwd)"
                break
            fi
        done
    fi
    if [ -z "$dir" ] || [ ! -f "$dir/bin/devenv-image-inspect" ]; then
        echo ""
        return 0
    fi
    echo "$dir"
}

resolve_helper() {
    local dir="${DEVENV_AI_HELPER_DIR:-${VIM_AI_HELPER_DIR:-}}"
    local helper=""

    if [ -n "$dir" ]; then
        if [ -f "$dir/devenv-ai-helper" ]; then
            helper="$(cd "$dir" && pwd)/devenv-ai-helper"
        elif [ -f "$dir/vim-ai-helper" ]; then
            helper="$(cd "$dir" && pwd)/vim-ai-helper"
        elif [ -f "$dir" ] && [ -x "$dir" ]; then
            helper="$(cd "$(dirname "$dir")" && pwd)/$(basename "$dir")"
        fi
    fi

    if [ -z "$helper" ]; then
        for candidate in \
            "$REPO_ROOT/../devenv-ai-helper/devenv-ai-helper" \
            "$REPO_ROOT/../vim-ai-helper/devenv-ai-helper" \
            "$REPO_ROOT/../vim-ai-helper/vim-ai-helper" \
            "$HOME/devenv-ai-helper/devenv-ai-helper" \
            "$HOME/vim-ai-helper/vim-ai-helper" \
            "$REPO_ROOT/.deps/devenv-ai-helper/devenv-ai-helper" \
            "$REPO_ROOT/.deps/vim-ai-helper/vim-ai-helper"; do
            if [ -f "$candidate" ]; then
                helper="$(cd "$(dirname "$candidate")" && pwd)/$(basename "$candidate")"
                break
            fi
        done
    fi

    if [ -z "$helper" ] && command -v devenv-ai-helper >/dev/null 2>&1; then
        helper="$(command -v devenv-ai-helper)"
    fi
    if [ -z "$helper" ] && command -v vim-ai-helper >/dev/null 2>&1; then
        helper="$(command -v vim-ai-helper)"
    fi

    if [ -z "$helper" ] || [ ! -f "$helper" ]; then
        die "devenv-ai-helper not found. Set DEVENV_AI_HELPER_DIR, clone sibling ../devenv-ai-helper, or install the RPM"
    fi
    echo "$helper"
}

ASSISTANT_DIR="$(resolve_assistant)"
LSP_SETUP_DIR="$(resolve_lsp_setup)"
FLOWCHART_DIR="$(resolve_code_flowchart)"
IMAGE_INSPECT_DIR="$(resolve_image_inspect)"
HELPER_BIN="$(resolve_helper)"

rm -rf "$CONTEXT_DIR"
mkdir -p "$CONTEXT_DIR/nvim/lua"

cp "$ASSISTANT_DIR/vimrc" "$CONTEXT_DIR/vimrc"
cp "$ASSISTANT_DIR/nvim-init.lua" "$CONTEXT_DIR/nvim/init.lua"
cp "$LSP_SETUP_DIR/lsp-config.lua" "$CONTEXT_DIR/nvim/lua/lsp-config.lua"
cp "$LSP_SETUP_DIR/treesitter-config.lua" "$CONTEXT_DIR/nvim/lua/treesitter-config.lua"
cp "$FLOWCHART_DIR/code-flowchart.lua" "$CONTEXT_DIR/nvim/lua/code-flowchart.lua"
# Flatpak historically referenced plugins-config.lua; provide empty stub if absent
if [ -f "$LSP_SETUP_DIR/plugins-config.lua" ]; then
    cp "$LSP_SETUP_DIR/plugins-config.lua" "$CONTEXT_DIR/nvim/lua/plugins-config.lua"
else
    printf '%s\n' "-- optional plugins config (stub for Flatpak)" >"$CONTEXT_DIR/nvim/lua/plugins-config.lua"
fi
cp "$HELPER_BIN" "$CONTEXT_DIR/devenv-ai-helper"
chmod +x "$CONTEXT_DIR/devenv-ai-helper"
ln -sfn devenv-ai-helper "$CONTEXT_DIR/vim-ai-helper"

if [ -n "$IMAGE_INSPECT_DIR" ]; then
    mkdir -p "$CONTEXT_DIR/nvim/lua" "$CONTEXT_DIR/vim/plugin" "$CONTEXT_DIR/vim/autoload"
    cp "$IMAGE_INSPECT_DIR/lua/image-inspect.lua" "$CONTEXT_DIR/nvim/lua/image-inspect.lua"
    cp "$IMAGE_INSPECT_DIR/plugin/image-inspect.vim" "$CONTEXT_DIR/vim/plugin/image-inspect.vim"
    cp "$IMAGE_INSPECT_DIR/autoload/image_inspect.vim" "$CONTEXT_DIR/vim/autoload/image_inspect.vim"
    cp "$IMAGE_INSPECT_DIR/bin/devenv-image-inspect" "$CONTEXT_DIR/devenv-image-inspect"
    chmod +x "$CONTEXT_DIR/devenv-image-inspect"
fi

# Editor containers install configs from COPR — do not stage into containers/{vim,neovim}.

echo "Prepared Flatpak build context:"
echo "  assistant:  $ASSISTANT_DIR"
echo "  lsp-setup:  $LSP_SETUP_DIR"
echo "  flowchart:  $FLOWCHART_DIR"
echo "  image-insp: ${IMAGE_INSPECT_DIR:-'(optional, not found)'}"
echo "  helper:     $HELPER_BIN"
echo "  staged:     $CONTEXT_DIR"
