local default_opts = require('linksmd.utils.opts')
local ufiles = require('linksmd.utils.files')
local plenary_path = require('plenary.path')

local M = {}

local function clear_globals(open_workspace, root_dir)
  _G.linksmd = {
    notebook = root_dir or nil,
    open_workspace = open_workspace or vim.fn.getcwd(),
    buffer = {
      id = nil,
      cursor = nil,
      line = nil,
    },
    flags = {
      pos = nil,
    },
    nui = {
      helper_quit = false,
      tree = {
        winid = nil,
        level = 0,
        parent_files = {},
        breadcrumb = {},
      },
    },
  }
end

M.setup = function(opts)
  local main_opts = default_opts

  if opts then
    main_opts = vim.tbl_deep_extend('force', main_opts, opts)
  end

  M.opts = main_opts

  clear_globals()
end

M.display = function(resource, display_init, follow_dir)
  vim.cmd('messages clear')

  if _G.linksmd.nui.tree.winid then
    vim.notify('[linksmd] You have an active operation', vim.log.levels.WARN, { render = 'minimal' })
    return
  end

  if display_init ~= nil and display_init ~= '' and (display_init == 'telescope' or display_init == 'nui') then
    M.opts.display_init = display_init
  end

  local root_dir = nil
  follow_dir = follow_dir or nil

  if _G.linksmd.notebook ~= nil then
    root_dir = _G.linksmd.notebook
  else
    root_dir = ufiles.get_root_dir()
  end

  if root_dir == nil then
    vim.notify('[linksmd] You need to go to any notebook', vim.log.levels.WARN, { render = 'minimal' })
    return
  end

  clear_globals(_G.linksmd.open_workspace, root_dir)

  if follow_dir ~= nil then
    if not plenary_path:new(follow_dir):exists() then
      vim.notify(
        '[linksmd] You need to pass a correct directory for this notebook or nil',
        vim.log.levels.WARN,
        { render = 'minimal' }
      )

      return
    end
  end

  _G.linksmd.buffer.id = vim.api.nvim_get_current_buf()
  _G.linksmd.buffer.cursor = vim.api.nvim_win_get_cursor(0)
  _G.linksmd.buffer.line = vim.api.nvim_get_current_line()

  _G.linksmd.flags.level = nil

  local flag = nil
  local level_flag = 1
  local load_flag = false
  local file_note = nil
  local current_notebook = true

  local buffer = _G.linksmd.buffer

  for data_filter in buffer.line:gmatch('%b()') do
    if data_filter:find('#') then
      flag = data_filter:sub(2, -2)

      if flag:find('^#') then
        if flag:find('^#$') then
          load_flag = true
          M.opts.resource = 'headers'
        else
          for kflag, vflag in pairs(M.opts.flags) do
            if '#' .. vflag == flag then
              load_flag = true
              M.opts.resource = kflag
              break
            end
          end
        end
      else
        local pos_a, pos_b = flag:find('^.*#$')

        if pos_a and pos_b then
          file_note = flag:sub(pos_a, pos_b - 1)

          local treat_file_note = string.gsub(file_note, '^' .. root_dir .. '/', '')

          local path_headers = nil
          if file_note == treat_file_note then
            path_headers = file_note
            current_notebook = false
          else
            file_note = treat_file_note
            path_headers = string.format('%s/%s', root_dir, treat_file_note)
          end

          if not plenary_path:new(path_headers):exists() then
            vim.notify(
              string.format('[linksd] No found the flag note in this notebook (%s)', root_dir),
              vim.log.levels.WARN,
              { render = 'minimal' }
            )
            return
          end

          load_flag = true
          M.opts.resource = 'headers'
        end
      end

      if load_flag then
        _G.linksmd.flags.level = level_flag
        break
      end
    end

    level_flag = level_flag + 1
  end

  if not load_flag then
    if M.opts.resources[resource] then
      M.opts.resource = resource
    else
      M.opts.resource = 'notes'
    end

    _G.linksmd.flags.level = nil
  end

  if M.opts.resource == 'headers' then
    if file_note == nil then
      local full_filename = vim.api.nvim_buf_get_name(0)

      file_note = string.gsub(full_filename, '^' .. root_dir .. '/', '')

      if file_note == full_filename then
        current_notebook = false
      end
    end

    require('linksmd.headers'):init(M.opts, root_dir, {}, file_note, current_notebook):launch()
    return
  end

  if M.opts.display_init == 'nui' then
    require('linksmd.manager'):init(M.opts, root_dir, follow_dir, {}):launch()
  elseif M.opts.display_init == 'telescope' then
    require('linksmd.finder'):init(M.opts, root_dir, {}, false):launch()
  else
    vim.notify('[linksmd] You need to configure the display_init', vim.log.levels.WARN, { render = 'minimal' })
  end
end
-- vim.cmd('message clear')
-- M.setup()
-- M.display(nil, 'nui')

return M
