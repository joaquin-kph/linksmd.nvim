local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local ufiles = require('linksmd.utils.files')

local DisplayTelescope = {}
DisplayTelescope.__index = DisplayTelescope

function DisplayTelescope:init(opts, root_dir, files, only_dirs)
  local data = {
    only_dirs = only_dirs,
    root_dir = root_dir,
    opts = opts,
    files = nil,
  }

  if not files.files or #files.files == 0 then
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

    data.files = ufiles.get_files(data.root_dir, data.opts.filters[data.opts.searching], false, only_dirs)
  else
    data.files = files
  end

  setmetatable(data, DisplayTelescope)

  return data
end

function DisplayTelescope:launch()
  local opts = {}

  local results = {}
  local prompt = nil

  if self.only_dirs then
    results = self.files.dirs
    prompt = 'Buscar Directorio'
  else
    results = self.files.files
    prompt = 'Buscar Nota'
  end

  pickers
    .new(opts, {
      prompt_title = prompt,
      finder = finders.new_table({
        results = results,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(bufnr, _)
        actions.select_default:replace(function()
          actions.close(bufnr)

          local selection = action_state.get_selected_entry()[1]

          if self.only_dirs then
            require('linksmd.manager'):init(self.opts, self.root_dir, selection, self.files, false):launch()
          else
            print(selection)
          end
        end)

        return true
      end,
    })
    :find()
end

return DisplayTelescope
