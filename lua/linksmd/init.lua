local default_opts = require('linksmd.utils.opts')
local ufiles = require('linksmd.utils.files')
local plenary_path = require('plenary.path')

local M = {}

M.setup = function(opts)
  local main_opts = default_opts

  if opts then
    main_opts = vim.tbl_deep_extend('force', main_opts, opts)
  end

  M.opts = main_opts

  _G.linksmd = {
    nui = {
      tree = {
        level = 0,
        parent_files = {},
        breadcrumb = {},
      },
    },
  }
end

M.display = function(resource, display_init, follow_dir)
  M.opts.buffer = {
    id = vim.api.nvim_get_current_buf(),
    cursor = vim.api.nvim_win_get_cursor(0),
    line = vim.api.nvim_get_current_line(),
  }

  if resource == 'flags' then
    M.opts.buffer.flag = nil

    local flag_changed = false

    for v in M.opts.buffer.line:gmatch('#%w+') do
      print(v)
      M.opts.buffer.flag = v:sub(2)

      for k2, v2 in pairs(M.opts.flags) do
        if v2 == M.opts.buffer.flag then
          M.opts.resource = k2
          flag_changed = true
          break
        end
      end

      if flag_changed then
        break
      end
    end

    if not flag_changed then
      M.opts.resource = 'notes'
    end
  elseif M.opts.resources[resource] then
    M.opts.resource = resource
  end

  if display_init ~= nil and display_init ~= '' then
    if display_init == 'telescope' or display_init == 'nui' then
      M.opts.display_init = display_init
    end
  end

  local root_dir = nil
  follow_dir = follow_dir or nil

  if M.opts.notebook_main ~= nil then
    if not plenary_path:new(M.opts.notebook_main):exists() then
      vim.notify(
        '[linksmd] You need to pass a correct notebook_main or nil',
        vim.log.levels.WARN,
        { render = 'minimal' }
      )
      return
    end

    root_dir = M.opts.notebook_main
  else
    root_dir = ufiles.get_root_dir()
  end

  if follow_dir ~= nil then
    if not plenary_path:new(follow_dir):exists() then
      vim.notify(
        '[linksmd] You need to pass a correct directory for this notebook or nil',
        vim.log.levels.WARN,
        { render = 'minimal' }
      )
    end
  end

  if root_dir == nil then
    vim.notify('[linksmd] You need to go to any notebook', vim.log.levels.WARN, { render = 'minimal' })
    return
  end

  if M.opts.resource == 'headers' then
    require('linksmd.headers'):init(M.opts, root_dir, 'aqui.md'):launch()
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
vim.cmd('message clear')
-- M.setup()
-- M.display(nil, 'nui')

return M
