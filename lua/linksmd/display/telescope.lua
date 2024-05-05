local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local utils = require('linksmd.utils')

local DisplayTelescope = {}
DisplayTelescope.__index = DisplayTelescope

function DisplayTelescope:init(opts, root_dir, files, only_dirs)
  local data = {
    root_dir = root_dir,
    opts = opts,
    files = files,
  }

  if not files.filtered or #files.filtered == 0 then
    local valid_filter = false

    for s, _ in pairs(data.opts.filters) do
      if s == data.opts.searching then
        valid_filter = true
        break
      end
    end

    if not valid_filter then
      vim.notify('[linksmd] You need to pass a valid searching', vim.log.levels.WARN, { render = 'minimal' })
      return
    end

    data.files = utils.get_files(data.root_dir, data.opts.filters[data.opts.searching], false, only_dirs)
  end

  setmetatable(data, DisplayTelescope)

  return data
end

function DisplayTelescope:launch()
  -- vim.cmd('messages clear')

  local opts = {}

  pickers
    .new(opts, {
      prompt_title = 'Buscador de Notas',
      finder = finders.new_table({
        results = self.files.filtered,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(bufnr, _)
        actions.select_default:replace(function()
          actions.close(bufnr)

          local selection = action_state.get_selected_entry()[1]

          print(selection)
        end)

        return true
      end,
    })
    :find()
end

return DisplayTelescope
