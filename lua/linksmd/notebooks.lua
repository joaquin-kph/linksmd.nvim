local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local dropdown = require('telescope.themes').get_dropdown()
local plenary_path = require('plenary.path')
local components = require('linksmd.utils.components')
local event = require('nui.utils.autocmd').event

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
    local title = notebook.title
    local path = notebook.path

    local list = ''

    if self.root_dir == path then
      list = string.format('%s  %s  %s %s', self.opts.custom.icons.notebook, '', title, path)
    else
      list = string.format('%s  %s  %s %s', self.opts.custom.icons.notebook, '', title, path)
    end

    return list
  end, self.opts.notebooks)

  local icon = ''

  if self.root_dir == _G.linksmd.open_workspace then
    icon = ''
  end

  table.insert(
    results,
    1,
    string.format(
      '%s  %s  %s %s',
      self.opts.custom.icons.workspace,
      icon,
      self.opts.custom.text.open_workspace,
      _G.linksmd.open_workspace
    )
  )

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
            if i == 5 then
              notebook = s
              break
            end
            i = i + 1
          end

          if notebook == nil then
            vim.notify('[linksmd] No load the notebook ;(', vim.log.levels.WARN, { render = 'minimal' })
            return
          end

          local old_root_dir = self.root_dir

          if notebook == self.opts.custom.text.open_workspace then
            self.root_dir = _G.linksmd.open_workspace
          else
            self.root_dir = vim.tbl_filter(function(n)
              if n.title == notebook then
                return true
              end

              return false
            end, self.opts.notebooks)[1].path
          end

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

          local Menu = components.menu(
            self.opts.custom.text.change_workspace,
            string.format('%s 󰜴 %s', old_root_dir, self.root_dir),
            { width = '90%', height = '10%' },
            { self.opts.custom.text.change_workspace_true, self.opts.custom.text.change_workspace_false },
            function(value)
              local item = value.text

              if self.opts.custom.text.change_workspace_true == item then
                vim.notify(
                  string.format('[linksmd] Changing the workspace to %s', self.root_dir),
                  vim.log.levels.INFO,
                  { minimal = true }
                )
                vim.fn.chdir(self.root_dir)
              end
            end
          )

          Menu:mount()

          Menu:on(event.BufLeave, function()
            if self.opts.display_init == 'nui' then
              require('linksmd.manager'):init(self.opts, self.root_dir, nil, {}):launch()
            elseif self.opts.display_init == 'telescope' then
              require('linksmd.finder'):init(self.opts, self.root_dir, {}, false):launch()
            end

            Menu:unmount()
          end)
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
