# Agent guide — devenv-packager

## Purpose

Build **container images** and **Flatpak** bundles for the devenv stack.
Owns `containers/{vim,neovim,lsp-servers}/` and `flatpak/` (`org.devenv.*`).

## LSP containers

**One image per language:** `ghcr.io/dsedgmen/devenv-packager/lsp-<id>`.

- Categories in `containers/lsp-servers/tiers.yaml`: **green** / **yellow** / **red** (not OCI tags).
- Host editors → `lsp-wrapper.sh` → `lsp-<id>:latest` over stdio (shippable only).
- One CI workflow per image (`build-lsp-<id>.yml`, `build-vim.yml`, `build-neovim.yml`) for independent status.
- Red languages build as `:candidate` (never `:latest`); promote with `promote-check.sh` / `promote-lsp-<id>.yml` then set `tier: yellow` / `ship: true`.

## Editor containers (vim / neovim)

Install Fedora packages plus COPR [`dsedgmen/devenv`](https://copr.fedorainfracloud.org/coprs/dsedgmen/devenv/) RPMs.
Configs and helpers come from those RPMs — **do not** `COPY` staged sibling files into the images.

## Flatpak

App IDs: `org.devenv.Neovim`, `org.devenv.Vim` (and matching extensions).

## Constraints

1. Flatpak still stages via `scripts/prepare-build-context.sh` (siblings / env dirs:
   assistant, helper, lsp-setup, **code-flowchart**, optional **image-inspect**).
2. Never commit `build-context/` or staged helper binaries.
3. No third-party AI API calls in CI.
4. Document registry / Flatpak ID renames in README.
5. Flowchart comes from `DEVENV_CODE_FLOWCHART_DIR` / `../devenv-code-flowchart`,
   not from devenv-lsp-setup.
6. Image-inspect is optional: stage when `DEVENV_IMAGE_INSPECT_DIR` /
   `../devenv-image-inspect` is present.

## Verify

- `./containers/lsp-servers/build.sh all`
- `./containers/lsp-servers/build.sh candidates`
- `./containers/lsp-servers/smoke-lsp.sh lsp-python:latest python`
- `./containers/neovim/build.sh`
- `./containers/vim/build.sh`
