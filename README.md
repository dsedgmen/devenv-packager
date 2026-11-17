# devenv-packager

[![LSP CI](https://github.com/dsedgmen/devenv-packager/actions/workflows/lsp-dispatch.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/lsp-dispatch.yml)
[![Build Flatpak](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-flatpak.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-flatpak.yml)
[![Build vim](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-vim.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-vim.yml)
[![Build neovim](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-neovim.yml/badge.svg)](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-neovim.yml)

Container images and Flatpak bundles for the devenv stack.

- **Per-language LSP images** — `lsp-<id>` (categories green / yellow / red in `tiers.yaml`, not tags)
- **vim / neovim** — Fedora editors + [COPR `dsedgmen/devenv`](https://copr.fedorainfracloud.org/coprs/dsedgmen/devenv/) RPMs
- **Flatpak** — `org.devenv.Neovim` / `org.devenv.Vim`

## LSP CI status

Shared packaging changes run **[LSP CI](https://github.com/dsedgmen/devenv-packager/actions/workflows/lsp-dispatch.yml)** (`lsp-dispatch.yml`), which builds **only the languages touched** in the diff (`fail-fast: false` per id). Manual rebuild/promote: `build-lsp-<id>` / `promote-lsp-<id>` workflow_dispatch. Categories from [`containers/lsp-servers/tiers.yaml`](containers/lsp-servers/tiers.yaml).

| Language | Category | Image | Manual build | Manual promote |
|----------|----------|-------|--------------|----------------|
| python | green | `lsp-python:latest` | [build-lsp-python](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-python.yml) | — |
| go | green | `lsp-go:latest` | [build-lsp-go](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-go.yml) | — |
| bash | green | `lsp-bash:latest` | [build-lsp-bash](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-bash.yml) | — |
| rust | green | `lsp-rust:latest` | [build-lsp-rust](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-rust.yml) | — |
| c-cpp | green | `lsp-c-cpp:latest` | [build-lsp-c-cpp](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-c-cpp.yml) | — |
| javascript | red | `lsp-javascript:candidate` | [build-lsp-javascript](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-javascript.yml) | [promote-lsp-javascript](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-javascript.yml) |
| typescript | red | `lsp-typescript:candidate` | [build-lsp-typescript](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-typescript.yml) | [promote-lsp-typescript](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-typescript.yml) |
| json | red | `lsp-json:candidate` | [build-lsp-json](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-json.yml) | [promote-lsp-json](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-json.yml) |
| yaml | red | `lsp-yaml:candidate` | [build-lsp-yaml](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-yaml.yml) | [promote-lsp-yaml](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-yaml.yml) |
| html | red | `lsp-html:candidate` | [build-lsp-html](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-html.yml) | [promote-lsp-html](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-html.yml) |
| css | red | `lsp-css:candidate` | [build-lsp-css](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-css.yml) | [promote-lsp-css](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-css.yml) |
| lua | red | `lsp-lua:candidate` | [build-lsp-lua](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-lua.yml) | [promote-lsp-lua](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-lua.yml) |
| java | red | `lsp-java:candidate` | [build-lsp-java](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-java.yml) | [promote-lsp-java](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-java.yml) |
| ruby | red | `lsp-ruby:candidate` | [build-lsp-ruby](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-ruby.yml) | [promote-lsp-ruby](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-ruby.yml) |

Red candidates build as `:candidate`. On `main`, LSP CI also runs promote for changed red ids (opens `promote/<id>` PR). Or use **Promote lsp-\<id\>** workflow_dispatch. Details: [containers/lsp-servers/README.md](containers/lsp-servers/README.md).

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
