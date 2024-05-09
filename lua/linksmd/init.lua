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

M.display = function(follow_dir)
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

  if M.opts.display_init == 'nui' then
    require('linksmd.manager'):init(M.opts, root_dir, follow_dir, {}):launch()
  elseif M.opts.display_init == 'telescope' then
    require('linksmd.finder'):init(M.opts, root_dir, {}, false):launch()
  else
    vim.notify('[linksmd] You need to configure the display_init', vim.log.levels.WARN, { render = 'minimal' })
  end
end

M.setup({ display = 'nui' })
M.display()

return M
