local plenary_scandir = require('plenary').scandir.scan_dir
local plenary_async = require('plenary.async')

local M = {}

M.get_root_dir = function()
  local mkdnflow_ok, mkdnflow = pcall(require, 'mkdnflow')

  if not mkdnflow_ok then
    vim.notify('[linksmd] You need add mkdnflow as dependency', vim.log.levels.WARN, { render = 'minimal' })

    return nil
  end

  return mkdnflow.root_dir
end

M.get_files = function(root_dir, extensions, hidden, only_dirs)
  local files = {
    all = {},
    filtered = {},
  }

  local scandir = plenary_scandir(root_dir, { hidden = hidden, only_dirs = true })
  print(vim.inspect(scandir))
  for i = #scandir, 1, -1 do
    table.insert(files.all, scandir[i])
  end

  local ext = string.format(',%s,', table.concat(extensions, ','))

  for _, file in ipairs(files.all) do
    local file_ext = file:gsub('.*%.', '')

    if string.find(ext, ',' .. file_ext .. ',') then
      local treat_file = string.gsub(file, '^' .. root_dir .. '/', '')
      table.insert(files.filtered, treat_file)
    end
  end

  return files
end

M.read_file = function(path)
  local err_open, fd = plenary_async.uv.fs_open(path, 'r', 438)
  if err_open then
    vim.notify('[linksmd] ' .. err_open, vim.log.levels.ERROR, { render = 'minimal' })
    return
  end

  local err_fstat, stat = plenary_async.uv.fs_fstat(fd)
  if err_fstat then
    vim.notify('[linksmd] ' .. err_fstat, vim.log.levels.ERROR, { render = 'minimal' })
    return
  end

  local err_read, data = plenary_async.uv.fs_read(fd, stat.size, 0)
  if err_read then
    vim.notify('[linksmd] ' .. err_read, vim.log.levels.ERROR, { render = 'minimal' })
    return
  end

  local err_close = plenary_async.uv.fs_close(fd)
  if err_close then
    vim.notify('[linksmd] ' .. err_close, vim.log.levels.ERROR, { render = 'minimal' })
    return
  end

  return data
end

return M
