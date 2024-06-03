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

M.menu = function(title, separator, size, items, on_submit)
  local lines = vim.tbl_map(function(item)
    return Menu.item(item)
  end, items)

  table.insert(
    lines,
    1,
    Menu.separator(separator, {
      text_align = 'left',
      char = '-',
    })
  )

  return Menu({
    position = '50%',
    size = {
      width = size.width,
      height = size.height,
    },
    win_options = {
      winhighlight = 'Normal:Normal',
    },
    border = {
      style = 'single',
      text = {
        top = title,
        top_align = 'center',
      },
    },
  }, {
    lines = lines,
    keymap = {
      focus_next = { 'j', '<down>', '<tab>', '<M-j>' },
      focus_prev = { 'k', '<up>', '<s-tab>', '<M-k>' },
      close = { '<esc>', '<M-q>', 'q' },
      submit = { '<cr>', '<space>' },
    },
    on_submit = on_submit,
  })
end

M.tree = function(bufnr)
  return Tree({
    bufnr = bufnr,
    nodes = {},
  })
end

return M
