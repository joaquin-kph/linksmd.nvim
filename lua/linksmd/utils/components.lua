local Popup = require('nui.popup')
local Menu = require('nui.menu')
local Tree = require('nui.tree')
local plenary_async = require('plenary.async')
local ufiles = require('linksmd.utils.files')

local M = {}

M.popup = function(enter, focusable, title, buf_options)
  buf_options = buf_options or {
    modifiable = true,
    readonly = false,
  }

  return Popup({
    enter = enter,
    focusable = focusable,
    buf_options = buf_options,
    border = {
      style = 'single',
      text = {
        top = title and string.format(' %s ', title) or nil,
        top_align = 'left',
      },
    },
  })
end

M.menu = function(title, items, bufnr_preview, root_dir)
  local lines = {}

  for _, v in ipairs(items) do
    table.insert(lines, Menu.item(v))
  end

  return Menu({
    border = {
      style = 'single',
      text = {
        top = title,
        top_align = 'center',
      },
    },
    position = {
      row = 1,
      col = 0,
    },
    win_options = {
      winhighlight = 'Normal:Normal',
    },
  }, {
    lines = lines,
    -- max_width = 20,
    keymap = {
      focus_next = { 'j', '<down>', '<tab>', '<M-j>' },
      focus_prev = { 'k', '<up>', '<s-tab>', '<M-k>' },
      close = { '<esc>', '<M-q>', 'q' },
      submit = { '<cr>', '<space>' },
    },
    on_change = function(item, _)
      local path = string.format('%s/%s', root_dir, item.text)

      plenary_async.run(function()
        local data = ufiles.read_file(path)
        local text = vim.split(data and data or '', '\n')

        vim.schedule(function()
          vim.api.nvim_buf_set_lines(bufnr_preview, 0, -1, false, text)

          vim.api.nvim_buf_call(bufnr_preview, function()
            if vim.api.nvim_buf_line_count(bufnr_preview) > 5 then
              vim.api.nvim_win_set_cursor(0, { 5, 0 })
            end
          end)
        end)
      end)
    end,
    on_submit = function(item)
      print(item.text)
    end,
  })
end

M.tree = function(bufnr)
  return Tree({
    bufnr = bufnr,
    nodes = {},
  })
end

return M
