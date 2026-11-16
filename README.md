# devenv-packager

[![Build Containers](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-containers.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-containers.yml)
[![Promote LSP](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp.yml)
[![Build Flatpak](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-flatpak.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-flatpak.yml)

Container images and Flatpak bundles for the devenv stack.

- **Per-language LSP images** — `lsp-<id>` (categories green / yellow / red in `tiers.yaml`, not tags)
- **vim / neovim** — Fedora editors + [COPR `dsedgmen/devenv`](https://copr.fedorainfracloud.org/coprs/dsedgmen/devenv/) RPMs
- **Flatpak** — `org.devenv.Neovim` / `org.devenv.Vim`

## LSP CI status

Categories and ship status from [`containers/lsp-servers/tiers.yaml`](containers/lsp-servers/tiers.yaml). Badges track the `lsp-<id>` matrix jobs on `main` ([Build Containers](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-containers.yml)).

| Language | Category | Image | CI |
|----------|----------|-------|----|
| python | green | `lsp-python` | [![lsp-python](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-containers.yml/badge.svg?branch=main)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-containers.yml) |
| go | green | `lsp-go` | [![lsp-go](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-containers.yml/badge.svg?branch=main)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-containers.yml) |
| bash | green | `lsp-bash` | [![lsp-bash](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-containers.yml/badge.svg?branch=main)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-containers.yml) |
| rust | green | `lsp-rust` | [![lsp-rust](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-containers.yml/badge.svg?branch=main)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-containers.yml) |
| c-cpp | green | `lsp-c-cpp` | [![lsp-c-cpp](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-containers.yml/badge.svg?branch=main)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-containers.yml) |
| javascript | red | — | not shipped |
| typescript | red | — | not shipped |
| json | red | — | not shipped |
| yaml | red | — | not shipped |
| html | red | — | not shipped |
| css | red | — | not shipped |
| lua | red | — | not shipped |
| java | red | — | not shipped |
| ruby | red | — | not shipped |

When promoting red → yellow, add a CI badge row for that `lsp-<id>` in the same PR. Details: [containers/lsp-servers/README.md](containers/lsp-servers/README.md).

## Build

```bash
./containers/lsp-servers/build.sh all
./containers/neovim/build.sh
./containers/vim/build.sh
```

Editor images install COPR packages (`devenv-ai-assistant`, `devenv-ai-helper`, `devenv-lsp-setup`, …) — no staged config copies.

Flatpak (still stages sibling sources via `prepare-build-context.sh`):

```bash
./scripts/prepare-build-context.sh
./flatpak/build-flatpak.sh
```

## Images / Flatpaks

```text
ghcr.io/dsedgmen/devenv-packager/lsp-python
ghcr.io/dsedgmen/devenv-packager/lsp-go
ghcr.io/dsedgmen/devenv-packager/lsp-bash
ghcr.io/dsedgmen/devenv-packager/lsp-rust
ghcr.io/dsedgmen/devenv-packager/lsp-c-cpp
ghcr.io/dsedgmen/devenv-packager/neovim
ghcr.io/dsedgmen/devenv-packager/vim

org.devenv.Neovim
org.devenv.Vim
```

## Related

| Project | Role |
|---------|------|
| [devenv](https://github.com/dsedgmen/devenv) | CLI / orchestration |
| [devenv-ai-assistant](https://github.com/dsedgmen/devenv-ai-assistant) | Editor AI configs (COPR) |
| [devenv-ai-helper](https://github.com/dsedgmen/devenv-ai-helper) | AI CLI (COPR) |
| [devenv-lsp-setup](https://github.com/dsedgmen/devenv-lsp-setup) | LSP + Tree-sitter (COPR) |
| [devenv-code-flowchart](https://github.com/dsedgmen/devenv-code-flowchart) | Offline call-graph (COPR) |
| [devenv-image-inspect](https://github.com/dsedgmen/devenv-image-inspect) | Image inspect (COPR) |

Agent guidance: [AGENTS.md](AGENTS.md).
