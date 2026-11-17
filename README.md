# devenv-packager

![Build Flatpak](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-flatpak.yml/badge.svg)
![Build vim](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-vim.yml/badge.svg)
![Build neovim](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-neovim.yml/badge.svg)

Container images and Flatpak bundles for the devenv stack.

- **Per-language LSP images** — `lsp-<id>` (categories green / yellow / red in `tiers.yaml`, not tags)
- **vim / neovim** — Fedora editors + [COPR `dsedgmen/devenv`](https://copr.fedorainfracloud.org/coprs/dsedgmen/devenv/) RPMs
- **Flatpak** — `org.devenv.Neovim` / `org.devenv.Vim`

## LSP CI status

Per-image workflow badges (status only). Unaffected languages skip the heavy build via `lang-in-diff`. Categories from [`containers/lsp-servers/tiers.yaml`](containers/lsp-servers/tiers.yaml). Manual rebuild/promote: see [containers/lsp-servers/README.md](containers/lsp-servers/README.md).

| Language | Category | Image | Build | Promote |
|----------|----------|-------|-------|---------|
| python | green | `lsp-python:latest` | ![lsp-python](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-python.yml/badge.svg) | — |
| go | green | `lsp-go:latest` | ![lsp-go](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-go.yml/badge.svg) | — |
| bash | green | `lsp-bash:latest` | ![lsp-bash](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-bash.yml/badge.svg) | — |
| rust | green | `lsp-rust:latest` | ![lsp-rust](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-rust.yml/badge.svg) | — |
| c-cpp | green | `lsp-c-cpp:latest` | ![lsp-c-cpp](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-c-cpp.yml/badge.svg) | — |
| javascript | red | `lsp-javascript:candidate` | ![lsp-javascript](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-javascript.yml/badge.svg) | ![promote-javascript](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-javascript.yml/badge.svg) |
| typescript | red | `lsp-typescript:candidate` | ![lsp-typescript](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-typescript.yml/badge.svg) | ![promote-typescript](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-typescript.yml/badge.svg) |
| json | red | `lsp-json:candidate` | ![lsp-json](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-json.yml/badge.svg) | ![promote-json](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-json.yml/badge.svg) |
| yaml | red | `lsp-yaml:candidate` | ![lsp-yaml](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-yaml.yml/badge.svg) | ![promote-yaml](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-yaml.yml/badge.svg) |
| html | red | `lsp-html:candidate` | ![lsp-html](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-html.yml/badge.svg) | ![promote-html](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-html.yml/badge.svg) |
| css | red | `lsp-css:candidate` | ![lsp-css](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-css.yml/badge.svg) | ![promote-css](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-css.yml/badge.svg) |
| lua | red | `lsp-lua:candidate` | ![lsp-lua](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-lua.yml/badge.svg) | ![promote-lua](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-lua.yml/badge.svg) |
| java | red | `lsp-java:candidate` | ![lsp-java](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-java.yml/badge.svg) | ![promote-java](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-java.yml/badge.svg) |
| ruby | red | `lsp-ruby:candidate` | ![lsp-ruby](https://github.com/dsedgmen/devenv-packager/actions/workflows/build-lsp-ruby.yml/badge.svg) | ![promote-ruby](https://github.com/dsedgmen/devenv-packager/actions/workflows/promote-lsp-ruby.yml/badge.svg) |

Red candidates build as `:candidate`. On `main`, promote CI for a changed red id opens a `promote/<id>` PR (`tier: yellow` / `ship: true`). Merge that PR to publish `:latest`.

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
