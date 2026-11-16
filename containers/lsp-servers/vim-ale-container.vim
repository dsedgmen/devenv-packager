" Vim ALE: point linters at containerized LSP via lsp-wrapper.sh
" Source from vimrc when VIM_LSP_MODE=container, e.g.:
"   if $VIM_LSP_MODE ==# 'container'
"     execute 'source' expand('$DEVENV_PACKAGER_DIR/containers/lsp-servers/vim-ale-container.vim')
"   endif

if !exists('$DEVENV_PACKAGER_DIR') || empty($DEVENV_PACKAGER_DIR)
  let s:wrapper = expand('~/claude/devenv-packager/containers/lsp-servers/lsp-wrapper.sh')
else
  let s:wrapper = expand('$DEVENV_PACKAGER_DIR/containers/lsp-servers/lsp-wrapper.sh')
endif

if !empty($DEVENV_LSP_WRAPPER)
  let s:wrapper = expand('$DEVENV_LSP_WRAPPER')
endif

let g:ale_linters = {
\   'python': ['pylsp'],
\   'go': ['gopls'],
\   'sh': ['bashls'],
\   'rust': ['analyzer'],
\   'c': ['clangd'],
\   'cpp': ['clangd'],
\}

let g:ale_python_pylsp_executable = s:wrapper
let g:ale_python_pylsp_options = 'python'

let g:ale_go_gopls_executable = s:wrapper
let g:ale_go_gopls_options = 'go'

let g:ale_sh_bashls_executable = s:wrapper
let g:ale_sh_bashls_options = 'bash'

let g:ale_rust_analyzer_executable = s:wrapper
let g:ale_rust_analyzer_options = 'rust'

let g:ale_c_clangd_executable = s:wrapper
let g:ale_c_clangd_options = 'clangd'
let g:ale_cpp_clangd_executable = s:wrapper
let g:ale_cpp_clangd_options = 'clangd'
