local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local previewers = require('telescope.previewers')
local ufiles = require('linksmd.utils.files')
local unode = require('linksmd.utils.node')

local DisplayFinder = {}
DisplayFinder.__index = DisplayFinder

function DisplayFinder:init(opts, root_dir, files, only_dirs)
  local data = {
    follow_dir = nil,
    only_dirs = only_dirs,
    root_dir = root_dir,
    open_preview = false,
    opts = opts,
    files = nil,
  }

  if opts.resource == 'notes' and data.only_dirs == false then
    data.open_preview = true
  end

  if not files.files or #files.files == 0 then
    local valid_filter = false

    for s, _ in pairs(data.opts.resources) do
      if s == data.opts.resource then
        valid_filter = true
        break
      end
    end

    if not valid_filter then
      vim.notify('[linksmd] You need to pass a valid resource', vim.log.levels.WARN, { render = 'minimal' })
      return
    end

    local dir_resource = data.opts.dir_resources[data.opts.resource] and data.opts.dir_resources[data.opts.resource]
      or nil

    data.files = ufiles.get_files(data.root_dir, data.opts.resources[data.opts.resource], dir_resource)
  else
    data.files = files
  end

  setmetatable(data, DisplayFinder)

  return data
end

function DisplayFinder:launch()
  local opts = {}

  local results = {}
  local prompt = nil
  local root_dir = self.root_dir

  if self.only_dirs then
    results = self.files.dirs
    prompt = 'Buscar Directorio'
  else
    results = self.files.files
    prompt = 'Buscar Nota'
  end

  if #results == 0 then
    vim.notify('[linksmd] No items in all notebook', vim.log.levels.WARN, { render = 'minimal' })
    return
  end

  pickers
    .new(opts, {
      prompt_title = prompt,
      finder = finders.new_table({
        results = results,
      }),
      sorter = conf.generic_sorter(opts),
      previewer = self.open_preview == true and previewers.new_buffer_previewer({
        ---@diagnostic disable-next-line: redefined-local
        define_preview = function(self, entry, _)
          unode.preview_data(root_dir, entry[1], function(text)
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, text)
          end)
        end,
      }),
      attach_mappings = function(bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()

          if selection == nil then
            vim.notify('[linksmd] You must select an option from menu', vim.log.levels.WARN, { render = 'minimal' })
            return true
          end

          actions.close(bufnr)

          if self.only_dirs then
            require('linksmd.manager'):init(self.opts, self.root_dir, selection[1], self.files):launch()
          else
            ufiles.apply_file(self.opts, selection[1])
          end
        end)

        map('i', self.opts.keymaps.search_file, function()
          require('linksmd.finder'):init(self.opts, self.root_dir, self.files, false):launch()
        end)
        map('i', self.opts.keymaps.search_dir, function()
          require('linksmd.finder'):init(self.opts, self.root_dir, self.files, true):launch()
        end)
        map('i', self.opts.keymaps.change_searching, function()
          require('linksmd.search'):init(self.opts, self.root_dir, self.files):launch()
        end)
        map('i', self.opts.keymaps.switch_manager, function()
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

return DisplayFinder
