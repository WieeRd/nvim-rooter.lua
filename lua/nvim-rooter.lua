local _config = {
  patterns = {},
  exclude_filetypes = {
    [''] = true,
    ['help'] = true,
    ['nofile'] = true,
    ['NvimTree'] = true,
    ['dashboard'] = true,
    ['TelescopePrompt'] = true,
  },
}

local function parent_dir(dir)
  return vim.fn.fnamemodify(dir, ':h')
end

local function change_dir(dir)
  dir = vim.fn.fnameescape(dir)
  vim.api.nvim_set_current_dir(dir)
  local result, module = pcall(require, 'nvim-tree.lib')
  if result then
    module.change_dir(dir)
  end
end

local function match(dir, pattern)
  if string.sub(pattern, 1, 1) == '=' then
    return vim.fn.fnamemodify(dir, ':t') == string.sub(pattern, 2, #pattern)
  else
    return vim.fn.globpath(dir, pattern) ~= ''
  end
end

local function activate()
  return not _config.manual
end

local function get_root()
  -- don't need to resove sybolic links explicitly, because
  -- `nvim_buf_get_name` returns the resolved path.
  local current = vim.api.nvim_buf_get_name(0)
  local parent = parent_dir(current)

  while 1 do
    for _, pattern in ipairs(_config.patterns) do
      if match(parent, pattern) then
        return parent
      end
    end

    current, parent = parent, parent_dir(parent)
    if parent == current then
      break
    end
  end
  return nil
end

local function rooter()
  if not activate() then
    return
  end

  if _config.exclude_filetypes[vim.bo.filetype] ~= nil then
    return nil
  end

  local root = vim.fn.exists('b:root_dir') == 1 and vim.api.nvim_buf_get_var(0, 'root_dir') or nil
  if root == nil then
    root = get_root()
    vim.api.nvim_buf_set_var(0, 'root_dir', root)
  end

  if root ~= nil then
    change_dir(root)
  end
end

local function rooter_toggle()
  local parent = parent_dir(vim.api.nvim_buf_get_name(0))
  if vim.fn.getcwd() ~= parent then
    change_dir(parent)
  else
    rooter()
  end
end

local function setup(opts)
  _config.patterns = opts.rooter_patterns == nil and { '.git', '.hg', '.svn' } or rooter_patterns
  _config.manual = opts.manual == nil and false or opts.manual
end

return {
  setup = setup,
  rooter = rooter,
  rooter_toggle = rooter_toggle,
}
