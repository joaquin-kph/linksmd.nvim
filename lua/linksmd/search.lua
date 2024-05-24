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

  local results = vim.tbl_map(function(key)
    local icon = self.opts.custom.icons[key]

    if key == 'headers' then
      return string.format('%s  %s', icon, key)
    else
      local dir = self.opts.dir_resources[key]

      if dir ~= nil then
        return string.format('%s  %s [#%s] %s%s', icon, key, self.opts.flags[key], self.opts.notebook_main, dir)
      else
        return string.format('%s  %s [#%s]', icon, key, self.opts.flags[key])
      end
    end
  end, vim.tbl_keys(self.opts.resources))

  local prompt = self.opts.custom.text.change_searching

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

          local i = 1
          for s in selection[1]:gmatch('(.-)%s') do
            if i == 3 then
              self.opts.resource = s
              break
            end
            i = i + 1
          end

          _G.linksmd.nui.tree.level = 0
          _G.linksmd.nui.tree.breadcrumb = {}
          _G.linksmd.nui.tree.parent_files = {}

          if self.opts.resource == 'headers' then
            require('linksmd.headers'):init(self.opts, self.root_dir, self.files, nil):launch()
            return
          end

          if self.opts.display_init == 'nui' then
            require('linksmd.manager'):init(self.opts, self.root_dir, nil, {}):launch()
          elseif self.opts.display_init == 'telescope' then
            require('linksmd.finder'):init(self.opts, self.root_dir, {}, false):launch()
          end
        end)

        map({ 'n', 'i' }, self.opts.keymaps.change_searching, function() end)
        map({ 'n', 'i' }, self.opts.keymaps.search_note, function()
          require('linksmd.finder'):init(self.opts, self.root_dir, self.files, false):launch()
        end)
        map({ 'n', 'i' }, self.opts.keymaps.search_dir, function()
          require('linksmd.finder'):init(self.opts, self.root_dir, self.files, true):launch()
        end)
        map({ 'n', 'i' }, self.opts.keymaps.switch_manager, function()
          actions.close(bufnr)

          local follow_dir = table.concat(_G.linksmd.nui.tree.breadcrumb, '/')

          require('linksmd.manager')
            :init(self.opts, self.root_dir, follow_dir ~= '' and follow_dir or nil, self.files)
            :launch()
        end)

        return true
      end,
    })
    :find()
end

return DisplaySearch
