local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local dropdown = require('telescope.themes').get_dropdown()

local DisplaySearch = {}
DisplaySearch.__index = DisplaySearch

function DisplaySearch:init(opts, root_dir, files)
  local data = {
    opts = opts,
    root_dir = root_dir,
    files = files,
  }

  setmetatable(data, DisplaySearch)

  return data
end

function DisplaySearch:launch()
  local opts = dropdown

  local results = vim.tbl_keys(self.opts.filters)
  local prompt = 'Establecer Filtro'

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

          self.opts.searching = selection[1]

          _G.linksmd.nui.tree.level = 0
          _G.linksmd.nui.tree.breadcrumb = {}
          _G.linksmd.nui.tree.parent_files = {}

          if self.opts.display_init == 'nui' then
            require('linksmd.manager'):init(self.opts, self.root_dir, nil, {}):launch()
          elseif self.opts.display_init == 'telescope' then
            require('linksmd.finder'):init(self.opts, self.root_dir, {}, false):launch()
          end
        end)

        map('i', self.opts.keymaps.search_file, function()
          require('linksmd.finder'):init(self.opts, self.root_dir, self.files, false):launch()
        end)
        map('i', self.opts.keymaps.search_dir, function()
          require('linksmd.finder'):init(self.opts, self.root_dir, self.files, true):launch()
        end)
        map('i', self.opts.keymaps.change_searching, function()
          require('linksmd.search'):init(self.opts, self.root_dir):launch()
        end)

        return true
      end,
    })
    :find()
end

return DisplaySearch
