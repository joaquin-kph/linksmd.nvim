local default_opts = require('linksmd.opts')
local DisplayNui = require('linksmd.display.nui')
local utils = require('linksmd.utils')
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

M.display = function(directory)
  local root_dir = nil
  directory = directory or nil

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
    root_dir = utils.get_root_dir()
  end

  if directory ~= nil then
    if not plenary_path:new(directory):exists() then
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

  if M.opts.display == 'nui' then
    DisplayNui:init(M.opts, root_dir, directory):launch()
  elseif M.opts.display == 'telescope' then
    print('USAR TELESCOPE')
  else
    vim.notify('[linksmd] You need to configure the display', vim.log.levels.WARN, { render = 'minimal' })
  end
end

M.setup({ display = 'nui' })
M.display('/home/hakyn/test/vault/notas/codigo/web')

return M
