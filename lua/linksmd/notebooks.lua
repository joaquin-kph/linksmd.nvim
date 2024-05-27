local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local dropdown = require('telescope.themes').get_dropdown()
local plenary_path = require('plenary.path')

local DisplayNotebooks = {}
DisplayNotebooks.__index = DisplayNotebooks

function DisplayNotebooks:init(opts, root_dir, files)
  local data = {
    opts = opts,
    root_dir = root_dir,
    files = files,
  }

  setmetatable(data, DisplayNotebooks)

  return data
end

function DisplayNotebooks:launch()
  local opts = dropdown

  local results = vim.tbl_map(function(notebook)
    local icon = notebook.icon
    local title = notebook.title
    local path = notebook.path

    return string.format('%s  %s %s', icon, title, path)
  end, self.opts.notebooks)

  local prompt = self.opts.custom.text.notebooks

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

          local notebook = nil

          local i = 1
          for s in selection[1]:gmatch('(.-)%s') do
            if i == 3 then
              notebook = s
              break
            end
            i = i + 1
          end

          self.root_dir = vim.tbl_filter(function(n)
            if n.title == notebook then
              return true
            end

            return false
          end, self.opts.notebooks)[1].path

          _G.linksmd.notebook = self.root_dir

          if not plenary_path:new(self.root_dir):exists() then
            vim.notify(
              string.format('[linksmd] No found the notebook (%s)', self.root_dir),
              vim.log.levels.WARN,
              { render = 'minimal' }
            )
            return
          end

          self.opts.resource = 'notes'

          if self.opts.display_init == 'nui' then
            require('linksmd.manager'):init(self.opts, self.root_dir, nil, {}):launch()
          elseif self.opts.display_init == 'telescope' then
            require('linksmd.finder'):init(self.opts, self.root_dir, {}, false):launch()
          end
        end)

        map({ 'n', 'i' }, self.opts.keymaps.change_notebooks, function() end)

        map({ 'n', 'i' }, self.opts.keymaps.change_searching, function()
          require('linksmd.search'):init(self.opts, self.root_dir, self.files):launch()
        end)

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

return DisplayNotebooks
