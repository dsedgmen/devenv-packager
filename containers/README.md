# Containers

Images owned by **devenv-packager** (Fedora base from `flatpak/FEDORA_VERSION`).

## Layout

```
containers/
├── lsp-servers/   # Per-language LSP images (lsp-<id>) + promotion framework
├── vim/           # Vim + dsedgmen/devenv COPR RPMs
└── neovim/        # Neovim + dsedgmen/devenv COPR RPMs
```

## Per-language LSP images

Host vim/neovim → `lsp-wrapper.sh` → `lsp-<id>:latest` (`--network=none`).

| Category | Rule |
|----------|------|
| Green | Fedora **LSP** RPM → ship `lsp-<id>` |
| Yellow | Promoted non-RPM (pin + smoke + Trivy) → ship `lsp-<id>` |
| Red | Not shipped (default until promotion) |

Green/yellow/red are **categories in** [lsp-servers/tiers.yaml](lsp-servers/tiers.yaml), **not** image tags.

```bash
./containers/lsp-servers/build.sh all
```

## Editor images

Configs/helpers come from COPR packages — no staged `COPY` of sibling repos.

```bash
./containers/vim/build.sh
./containers/neovim/build.sh
```

COPR: https://copr.fedorainfracloud.org/coprs/dsedgmen/devenv/
