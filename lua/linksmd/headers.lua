local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local dropdown = require('telescope.themes').get_dropdown()
local node = require('linksmd.utils.node')
local ufiles = require('linksmd.utils.files')
local plenary_path = require('plenary.path')

local function get_file_note(display)
  local file_note = nil
  local file_current_notebook = true
  local buffer = _G.linksmd.buffer

  local level = 1

  for data_filter in buffer.line:gmatch('%b()') do
    if level == _G.linksmd.flags.level then
      data_filter = data_filter:sub(2, -2)

      local pos_a, pos_b = data_filter:find('^.*#$')

      if pos_a and pos_b then
        file_note = data_filter:sub(pos_a, pos_b - 1)

        if not file_note or file_note == '' then
          file_note = nil
          break
        end

        if not plenary_path:new(string.format('%s/%s', display.root_dir, file_note)):exists() then
          file_note = nil
          break
        end
      end
      break
    end

    level = level + 1
  end

  if file_note == nil then
    local full_filename = vim.api.nvim_buf_get_name(0)

    file_note = string.gsub(full_filename, '^' .. display.root_dir .. '/', '')

    if full_filename == file_note then
      file_current_notebook = false
    end
  end

  return file_note, file_current_notebook
end

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

          ufiles.apply_file(header)
        end)

        map('i', display.opts.keymaps.change_searching, function()
          require('linksmd.search'):init(display.opts, display.root_dir, display.files):launch()
        end)

        map({ 'n', 'i' }, display.opts.keymaps.change_notebooks, function()
          require('linksmd.notebooks'):init(display.opts, display.root_dir, display.files):launch()
        end)

        map({ 'n', 'i' }, display.opts.keymaps.search_note, function() end)

        map({ 'n', 'i' }, display.opts.keymaps.search_dir, function() end)

        map({ 'n', 'i' }, display.opts.keymaps.switch_manager, function() end)

        return true
      end,
    })
    :find()
end

local DisplayHeaders = {}
DisplayHeaders.__index = DisplayHeaders

function DisplayHeaders:init(opts, root_dir, files, file)
  local data = {
    opts = opts,
    root_dir = root_dir,
    files = files,
    file = file,
    file_current_notebook = true,
  }

  if file == nil then
    data.file, data.file_current_notebook = get_file_note(data)
  end

  setmetatable(data, DisplayHeaders)

  return data
end

function DisplayHeaders:launch()
  node.preview_data(self.root_dir, self.file, self.file_current_notebook, function(text)
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
    local prompt = string.format('%s [%s]', self.opts.custom.text.headers, self.file)

    launch_picker(self, opts, prompt, results)
  end)
end

return DisplayHeaders
