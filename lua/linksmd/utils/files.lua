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

M.get_files = function(root_dir, extensions, dir_resource)
  local files = {
    all = {},
    files = {},
    dirs = {},
  }

  local dir_files = root_dir

  if dir_resource ~= nil then
    dir_files = dir_files .. dir_resource
  end

  local scandir = plenary_scandir(dir_files, { hidden = false })

  for i = #scandir, 1, -1 do
    table.insert(files.all, scandir[i])
  end

  local ext = string.format(',%s,', table.concat(extensions, ','))

  for _, file in ipairs(files.all) do
    local file_ext = file:gsub('.*%.', '')

    if string.find(ext, ',' .. file_ext .. ',') then
      local treat_file = string.gsub(file, '^' .. root_dir .. '/', '')

      table.insert(files.files, treat_file)

      for dir in treat_file:gmatch('(.+)/.+%.' .. file_ext .. '$') do
        if not vim.tbl_contains(files.dirs, dir) then
          table.insert(files.dirs, dir)
        end
      end
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

M.read_helper = function(bufnr_helper, keymaps, flags)
  local function treat_data(data)
    local keys_len = 10
    local new_data = data

    if #data < keys_len then
      for _ = 1, keys_len - #data do
        new_data = new_data .. ' '
      end
    end

    return new_data
  end

  local lines = {}

  local lines_flags = {
    ' Available flags',
    '-------------------------------------------------------',
  }
  for _, v in ipairs(lines_flags) do
    table.insert(lines, v:upper())
  end

  local the_flags = {
    notes = 'Get a note',
    books = 'Get a book',
    images = 'Get an image',
    sounds = 'Get a sound',
    headers = 'Get a header',
  }

  for k, v in pairs(flags) do
    local flag = the_flags[k] or nil

    if flag ~= nil then
      table.insert(lines, string.format(' %s %s', treat_data('#' .. v), flag))
    end
  end

  local lines_keymaps = {
    '',
    ' List of all keymaps',
    '-------------------------------------------------------',
  }

  for _, v in ipairs(lines_keymaps) do
    table.insert(lines, v:upper())
  end

  local actions = {
    menu_enter = 'Open directory',
    menu_back = 'Go to back',
    menu_down = 'Move to down [menu]',
    menu_up = 'Move to up [menu]',
    scroll_preview_down = 'Scroll down [preview]',
    scroll_preview_up = 'Scroll up [preview]',
    search_note = 'Searching note [telescope]',
    search_dir = 'Searching directory [telescope]',
    change_searching = 'Switch of links [telescope]',
    switch_manager = 'Menu nodes [Only works in telescope]',
    helper = 'Show helper [Only works in menu]',
    helper_quit = 'Exit from helper',
  }

  for k, v in pairs(keymaps) do
    local action = actions[k] or nil

    if action ~= nil then
      if type(v) == 'table' then
        for i, v2 in ipairs(v) do
          if i == 1 then
            table.insert(lines, string.format(' %s %s', treat_data(v2), action))
          else
            table.insert(lines, string.format('  └╴%s', treat_data(v2)))
          end
        end
      else
        table.insert(lines, string.format(' %s %s', treat_data(v), action))
      end
    end
  end

  vim.api.nvim_buf_set_lines(bufnr_helper, 0, -1, false, lines)
end

local replace_line = function(line, regex, replace, n_ocurrence)
  local pos_a, pos_b = 1, 0
  local middle_flag = false

  for _ = 1, n_ocurrence do
    pos_a, pos_b = line:find(regex, pos_b + 1)

    local original = line:sub(pos_a + 1, pos_b - 1)

    local simbol_pos = original:find('#')

    middle_flag = false
    if simbol_pos ~= nil and simbol_pos > 1 and (pos_a + simbol_pos) < pos_b then
      pos_a = pos_a + simbol_pos
      middle_flag = true
    end

    if not pos_a then
      break
    end
  end

  if pos_a then
    local part_a = line:sub(1, pos_a - 1)
    local part_b = line:sub(pos_b + 1)

    if middle_flag then
      replace = replace:sub(2, -1)
    end

    return string.format('%s%s%s', part_a, replace, part_b)
  end

  return line
end

M.apply_file = function(file, root_dir)
  if root_dir ~= vim.fn.getcwd() then
    file = string.gsub(file, '^' .. root_dir .. '/', '')

    if file:find('^#') then
      file = file
    else
      file = string.format('%s/%s', root_dir, file)
    end
  end

  local link_line = nil
  local cursor_col_start = nil
  local cursor_col_end = nil

  local buffer = _G.linksmd.buffer

  if _G.linksmd.flags.level then
    link_line = replace_line(buffer.line, '%b()', string.format('(%s)', file), _G.linksmd.flags.level)
    cursor_col_start = 0
    cursor_col_end = buffer.line:len()
  else
    link_line = file
    cursor_col_start = buffer.cursor[2]
    cursor_col_end = buffer.cursor[2]
  end

  vim.api.nvim_buf_set_text(
    buffer.id,
    buffer.cursor[1] - 1,
    cursor_col_start,
    buffer.cursor[1] - 1,
    cursor_col_end,
    { link_line }
  )
end

return M
