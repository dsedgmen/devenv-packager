-- Neovim: attach to per-language LSP containers over stdio.
-- Drop-in when VIM_LSP_MODE=container.
--
-- Wrapper resolution (first hit wins):
--   1) DEVENV_LSP_WRAPPER
--   2) DEVENV_PACKAGER_DIR/containers/lsp-servers/lsp-wrapper.sh
--   3) <this-file>/lsp-wrapper.sh
--   4) ~/claude/devenv-packager/containers/lsp-servers/lsp-wrapper.sh
--
-- Images: lsp-<id>:latest (categories green/yellow in tiers.yaml — not tags).

local function find_wrapper()
  local env = vim.env.DEVENV_LSP_WRAPPER
  if env and vim.fn.executable(env) == 1 then
    return env
  end
  local packager = vim.env.DEVENV_PACKAGER_DIR
  if packager and packager ~= "" then
    local p = packager .. "/containers/lsp-servers/lsp-wrapper.sh"
    if vim.fn.filereadable(p) == 1 then
      return p
    end
  end
  local here = debug.getinfo(1, "S").source:sub(2)
  local dir = vim.fn.fnamemodify(here, ":h")
  local sibling = dir .. "/lsp-wrapper.sh"
  if vim.fn.filereadable(sibling) == 1 then
    return sibling
  end
  local fallback = vim.fn.expand("~/claude/devenv-packager/containers/lsp-servers/lsp-wrapper.sh")
  if vim.fn.filereadable(fallback) == 1 then
    return fallback
  end
  return nil
end

local function has_runtime()
  return vim.fn.executable("podman") == 1 or vim.fn.executable("docker") == 1
end

local function on_attach(_, bufnr)
  local opts = { buffer = bufnr, noremap = true, silent = true }
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
  vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
  vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
  vim.keymap.set("n", "<leader>f", function()
    vim.lsp.buf.format({ async = true })
  end, opts)
  vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
  vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
  vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
  vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)
end

local function setup_container_lsp(name, wrapper_arg)
  local wrapper = find_wrapper()
  if not wrapper then
    vim.notify("lsp-wrapper.sh not found; set DEVENV_PACKAGER_DIR or DEVENV_LSP_WRAPPER", vim.log.levels.ERROR)
    return
  end
  local root_dir = vim.fn.getcwd()
  vim.lsp.start({
    name = name .. "-container",
    cmd = { wrapper, wrapper_arg },
    root_dir = root_dir,
    on_attach = on_attach,
  })
end

if not has_runtime() then
  vim.notify("podman/docker not found — cannot use containerized LSP", vim.log.levels.WARN)
  return
end

-- Shippable green languages only (see tiers.yaml). Red languages are not wired.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    setup_container_lsp("pylsp", "python")
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function()
    setup_container_lsp("gopls", "go")
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "sh", "bash" },
  callback = function()
    setup_container_lsp("bashls", "bash")
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function()
    setup_container_lsp("rust-analyzer", "rust")
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function()
    setup_container_lsp("clangd", "clangd")
  end,
})
