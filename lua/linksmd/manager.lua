local Layout = require('nui.layout')
local event = require('nui.utils.autocmd').event
local ufiles = require('linksmd.utils.files')
local components = require('linksmd.utils.components')
local node = require('linksmd.utils.node')
local mappings = require('linksmd.utils.mappings')

local DisplayNui = {}
DisplayNui.__index = DisplayNui

function DisplayNui:init(opts, root_dir, follow_dir, files)
  if follow_dir ~= nil then
    follow_dir = string.gsub(follow_dir, '^' .. root_dir .. '/', '')
  end

  local data = {
    root_dir = root_dir,
    opts = opts,
    preview = {
      state = true,
    },
    files = nil,
    follow_dir = follow_dir,
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

    data.files = ufiles.get_files(data.root_dir, data.opts.filters[data.opts.searching])
  else
    data.files = files
  end

  setmetatable(data, DisplayNui)

  return data
end

function DisplayNui:launch()
  local nodes = {}
  local node_ids = {}

  for _, file in ipairs(self.files.files) do
    local parts = vim.split(file, '/')

    nodes = node.node_files(file, parts, nodes, node_ids)
  end

  if #nodes == 0 then
    vim.notify(
      string.format('[linksmd] No found notes in this notebook (%s)', self.opts.notebook_main),
      vim.log.levels.WARN,
      { render = 'minimal' }
    )
    return
  end

  local popup_preview = components.popup(false, false, self.opts.text.preview)
  local popup_tree = components.popup(true, true, self.opts.text.menu)
  local menu_tree = components.tree(popup_tree.bufnr)

  popup_tree.border:set_text('bottom', string.format(' Notebook: %s ', self.opts.notebook_main), 'right')

  local layout = Layout(
    {
      position = '50%',
      size = {
        width = '70%',
        height = '50%',
      },
    },
    Layout.Box({
      Layout.Box(popup_preview, { size = '60%' }),
      Layout.Box(popup_tree, { size = '40%' }),
    }, { dir = 'col' })
  )

  local tree = node.node_tree(nodes, {})
  if self.follow_dir ~= nil then
    _G.linksmd.nui.tree.level = 0
    _G.linksmd.nui.tree.breadcrumb = {}
    _G.linksmd.nui.tree.parent_files = {}

    tree = node.node_tree_follow(tree, vim.split(self.follow_dir, '/'))

    popup_tree.border:set_text(
      'top',
      string.format(' %s -> %s ', self.opts.text.menu, table.concat(_G.linksmd.nui.tree.breadcrumb, '/')),
      'left'
    )
  end

  menu_tree:set_nodes(tree)

  layout:mount()
  menu_tree:render()

  mappings.enter(self, menu_tree, popup_tree, popup_preview)
  mappings.back(self, menu_tree, popup_tree, popup_preview)
  mappings.menu_up(self, menu_tree, popup_tree, popup_preview)
  mappings.menu_down(self, menu_tree, popup_tree, popup_preview)
  mappings.sroll_preview(self, layout, menu_tree, popup_tree, popup_preview)
  mappings.scroll_up(self, popup_tree, popup_preview)
  mappings.scroll_down(self, popup_tree, popup_preview)
  mappings.search_file(self, popup_tree)
  mappings.search_dir(self, popup_tree)
  mappings.change_searching(self, popup_tree)

  popup_tree:on(event.BufLeave, function()
    popup_preview:unmount()
    popup_tree:unmount()
  end)
end

return DisplayNui
