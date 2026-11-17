# Per-language LSP containers

This packaging tree builds **one OCI image per language server**.

```
Host editor ──stdio──► lsp-wrapper.sh ──podman run -i --network=none──► lsp-<id>:latest
```

## Categories (not tags)

| Category | Meaning | Image tag |
|----------|---------|-----------|
| **green** | Fedora LSP RPM | `lsp-<id>:latest` |
| **yellow** | Non-RPM LSP after promote-check | `lsp-<id>:latest` |
| **red** | Pinned candidate (not shipped) | `lsp-<id>:candidate` only |

Source of truth: [`tiers.yaml`](tiers.yaml). Tags are `latest` / `candidate` / sha / branch — never `:green` or `:yellow`. Category is an OCI label: `org.devenv.lsp.tier`.

Each language has its own GitHub Actions workflow (`build-lsp-<id>.yml`) so one failure does not fail the others.

## Shippable now (green)

| id | Image | Fedora package |
|----|-------|----------------|
| `python` | `lsp-python` | `python3-lsp-server` |
| `go` | `lsp-go` | `gopls` |
| `bash` | `lsp-bash` | `nodejs-bash-language-server` |
| `rust` | `lsp-rust` | `rust-analyzer` |
| `c-cpp` | `lsp-c-cpp` | `clang-tools-extra` (`clangd`) |

## Red candidates → yellow promotion

Red languages have pins + Containerfile targets and CI builds `:candidate` images. Host editors still use `:latest` only for shippable languages.

| id | Pin source |
|----|------------|
| `javascript` / `typescript` | npm `typescript-language-server` + `typescript` |
| `json` / `html` / `css` | npm `vscode-langservers-extracted` |
| `yaml` | npm `yaml-language-server` |
| `lua` | GitHub LuaLS release tarball |
| `java` | Eclipse JDT LS milestone + Fedora JRE |
| `ruby` | gem `ruby-lsp` |

1. Candidate CI: `build-lsp-<id>.yml` (build + provisional smoke + Trivy).
2. Promote gate: `./promote-check.sh <id>` or run `promote-lsp-<id>.yml` (Actions → workflow_dispatch, or push to `main` that touches LSP packaging).
3. When promote-check passes on `main` / dispatch, the workflow opens a PR (`promote/<id>`) that sets `tier: yellow` / `ship: true` and flips the Containerfile tier label. Merge that PR to publish `:latest`.

Repo setting required for step 3 automation: **Settings → Actions → General → Allow GitHub Actions to create and approve pull requests** (and workflow permissions **Read and write**).

Local equivalent of step 3: `./apply-promote.sh <id>` then open the PR yourself.

## Build

```bash
./build.sh python          # → lsp-python:latest
./build.sh javascript      # → lsp-javascript:candidate
./build.sh all             # all shippable (green + yellow)
./build.sh candidates      # all red → :candidate
./smoke-lsp.sh lsp-python:latest python
./smoke-lsp.sh --provisional lsp-javascript:candidate javascript
./promote-check.sh lua
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
