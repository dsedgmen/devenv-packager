# devenv-packager

[![Build Flatpak](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-flatpak.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-flatpak.yml)
[![Build vim](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-vim.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-vim.yml)
[![Build neovim](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-neovim.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-neovim.yml)

Container images and Flatpak bundles for the devenv stack.

- **Per-language LSP images** — `lsp-<id>` (categories green / yellow / red in `tiers.yaml`, not tags)
- **vim / neovim** — Fedora editors + [COPR `dsedgmen/devenv`](https://copr.fedorainfracloud.org/coprs/dsedgmen/devenv/) RPMs
- **Flatpak** — `org.devenv.Neovim` / `org.devenv.Vim`

## LSP CI status

Each image has its own workflow (independent check + badge). Categories from [`containers/lsp-servers/tiers.yaml`](containers/lsp-servers/tiers.yaml).

| Language | Category | Image | Build CI | Promote CI |
|----------|----------|-------|----------|------------|
| python | green | `lsp-python:latest` | [![lsp-python](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-python.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-python.yml) | — |
| go | green | `lsp-go:latest` | [![lsp-go](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-go.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-go.yml) | — |
| bash | green | `lsp-bash:latest` | [![lsp-bash](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-bash.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-bash.yml) | — |
| rust | green | `lsp-rust:latest` | [![lsp-rust](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-rust.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-rust.yml) | — |
| c-cpp | green | `lsp-c-cpp:latest` | [![lsp-c-cpp](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-c-cpp.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-c-cpp.yml) | — |
| javascript | red | `lsp-javascript:candidate` | [![lsp-javascript](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-javascript.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-javascript.yml) | [![promote](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-javascript.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-javascript.yml) |
| typescript | red | `lsp-typescript:candidate` | [![lsp-typescript](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-typescript.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-typescript.yml) | [![promote](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-typescript.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-typescript.yml) |
| json | red | `lsp-json:candidate` | [![lsp-json](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-json.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-json.yml) | [![promote](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-json.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-json.yml) |
| yaml | red | `lsp-yaml:candidate` | [![lsp-yaml](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-yaml.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-yaml.yml) | [![promote](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-yaml.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-yaml.yml) |
| html | red | `lsp-html:candidate` | [![lsp-html](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-html.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-html.yml) | [![promote](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-html.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-html.yml) |
| css | red | `lsp-css:candidate` | [![lsp-css](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-css.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-css.yml) | [![promote](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-css.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-css.yml) |
| lua | red | `lsp-lua:candidate` | [![lsp-lua](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-lua.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-lua.yml) | [![promote](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-lua.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-lua.yml) |
| java | red | `lsp-java:candidate` | [![lsp-java](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-java.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-java.yml) | [![promote](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-java.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-java.yml) |
| ruby | red | `lsp-ruby:candidate` | [![lsp-ruby](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-ruby.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-ruby.yml) | [![promote](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-ruby.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-ruby.yml) |

Red candidates build and test as `:candidate`. When promote CI for that id is green on `main` (or via workflow_dispatch), it opens a `promote/<id>` PR to set `tier: yellow` / `ship: true`. Merge that PR to publish `:latest`. Details: [containers/lsp-servers/README.md](containers/lsp-servers/README.md).

## Build

```bash
./containers/lsp-servers/build.sh all          # shippable → :latest
./containers/lsp-servers/build.sh candidates   # red → :candidate
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
