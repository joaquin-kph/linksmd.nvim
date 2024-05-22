local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local dropdown = require('telescope.themes').get_dropdown()
local node = require('linksmd.utils.node')
local ufiles = require('linksmd.utils.files')

local function launch_picker(display, opts, prompt, results)
  pickers
    .new(opts, {
      prompt_title = prompt,
      finder = finders.new_table({
        results = results,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()

          if selection == nil then
            vim.notify('[linksmd] You must select an option from menu', vim.log.levels.WARN, { render = 'minimal' })
            return true
          end

          actions.close(bufnr)

          local header = '#'
            .. selection[1]:lower():gsub('[^%a%s%d%-_]', ''):gsub('^ *', ''):gsub(' ', '-'):gsub('%-%-', '-')

          ufiles.apply_file(display.opts, header)
        end)

        return true
      end,
    })
    :find()
end

local DisplayHeaders = {}
DisplayHeaders.__index = DisplayHeaders

function DisplayHeaders:init(opts, root_dir, file)
  local data = {
    opts = opts,
    root_dir = root_dir,
    file = file,
  }

  setmetatable(data, DisplayHeaders)

  return data
end

function DisplayHeaders:launch()
  node.preview_data(self.root_dir, self.file, function(text)
    local headers = vim.tbl_filter(function(line)
      if line:match('^#+%s+') then
        return true
      end
      return false
    end, text)

    local opts = dropdown

    if #headers == 0 then
      vim.notify('[linksmd] The note no has headers', vim.log.levels.WARN, { render = 'minimal' })
      return
    end

    local results = headers
    local prompt = 'Establecer Filtro'

    launch_picker(self, opts, prompt, results)
  end)
end

return DisplayHeaders
