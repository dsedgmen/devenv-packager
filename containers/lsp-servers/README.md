# Per-language LSP containers

This packaging tree builds **one OCI image per language server**.

```
Host editor ──stdio──► lsp-wrapper.sh ──podman run -i --network=none──► lsp-<id>:latest
```

## Categories (not tags)

| Category | Meaning | Image |
|----------|---------|-------|
| **green** | Fedora LSP RPM | `ghcr.io/dsedgmen/devenv-packager/lsp-<id>` |
| **yellow** | Non-RPM LSP after pin + smoke + Trivy | same naming |
| **red** | Not packaged | — |

Source of truth: [`tiers.yaml`](tiers.yaml). Image tags are `latest` / sha / branch — never `:green` or `:yellow`. Category is an OCI label: `org.devenv.lsp.tier`.

## Shippable now (green)

| id | Image | Fedora package |
|----|-------|----------------|
| `python` | `lsp-python` | `python3-lsp-server` |
| `go` | `lsp-go` | `gopls` |
| `bash` | `lsp-bash` | `nodejs-bash-language-server` |
| `rust` | `lsp-rust` | `rust-analyzer` |
| `c-cpp` | `lsp-c-cpp` | `clang-tools-extra` (`clangd`) |

## Red → yellow promotion

Grammar-only / non-RPM languages start **red** (`javascript`, `typescript`, `json`, `yaml`, `html`, `css`, `lua`, `java`, `ruby`).

1. Add a **pin** (version/url/checksum) and `binary` / `command` in `tiers.yaml`.
2. Add a Containerfile target `AS <id>` with the pinned install.
3. Run `./promote-check.sh <id>` (build + smoke + Trivy) — also [`promote-lsp.yml`](../../.github/workflows/promote-lsp.yml).
4. In the **same PR**, set `tier: yellow` and `ship: true`.

Until that passes, `build.sh` refuses the id and no image is published.

## Build

```bash
./build.sh python          # → lsp-python:latest
./build.sh all             # all shippable (green + yellow)
./smoke-lsp.sh lsp-python:latest python
./promote-check.sh lua     # fails until pin + target exist
```

Fedora version: `flatpak/FEDORA_VERSION`.

## Wrapper

```bash
./lsp-wrapper.sh python
# LSP_IMAGE=lsp-python:latest   # optional override
# LSP_WORKSPACE=/path/to/project
# CONTAINER_RUNTIME=podman|docker
```

## Neovim / Vim

```bash
export DEVENV_PACKAGER_DIR=/path/to/devenv-packager
export VIM_LSP_MODE=container
```

See `neovim-container-lsp.lua` and `vim-ale-container.vim`.
