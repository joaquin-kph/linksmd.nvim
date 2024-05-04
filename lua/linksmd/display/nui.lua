local Popup = require('nui.popup')
local Layout = require('nui.layout')
local Menu = require('nui.menu')
local Tree = require('nui.tree')
local event = require('nui.utils.autocmd').event
local utils = require('linksmd.utils')
local plenary_async = require('plenary.async')

local function nui_popup(enter, focusable, title)
  return Popup({
    enter = enter,
    focusable = focusable,
    border = {
      style = 'single',
      text = {
        top = title and string.format(' %s ', title) or nil,
        top_align = 'left',
      },
    },
  })
end

local function nui_tree(bufnr)
  return Tree({
    bufnr = bufnr,
    nodes = {},
  })
end

local function nui_menu(title, items, bufnr_preview, root_dir)
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
        local data = utils.read_file(path)
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

local function node_tree_follow(tree, follow_dir, final_tree)
  if #follow_dir == 0 then
    return final_tree
  end

  for i, v in ipairs(tree) do
    if v.text == follow_dir[1] then
      table.remove(follow_dir, 1)

      table.insert(_G.linksmd.nui.tree.parent_files, tree)
      _G.linksmd.nui.tree.level = _G.linksmd.nui.tree.level + 1
      table.insert(_G.linksmd.nui.tree.breadcrumb, v.text)

      if tree[i].children then
        final_tree = node_tree_follow(tree[i].children, follow_dir, tree[i].children)
      end
      break
    end
  end

  return final_tree
end

local function node_tree(nodes, tree)
  local item_pos = 1

  for i, v in ipairs(nodes) do
    if #v == 0 then
      local child_tree = nil

      if nodes[i + 1] and #nodes[i + 1] > 0 then
        child_tree = node_tree(nodes[i + 1], {})
      end

      if child_tree ~= nil then
        -- table.insert(tree, { DIR = v.text, children = child_tree })
        table.insert(tree, Tree.Node({ text = v.text, file = v.file, children = child_tree, item_pos = item_pos }))
      else
        -- table.insert(tree, { FILE = v.text })
        table.insert(tree, Tree.Node({ text = v.text, file = v.file, item_pos = item_pos }))
      end

      item_pos = item_pos + 1
    end
  end

  return tree
end

local function node_tree2(nodes)
  local tree = {}

  local item_pos = 1
  for i, v in ipairs(nodes) do
    if #v == 0 then
      local child_tree = nil

      if nodes[i + 1] and #nodes[i + 1] > 0 then
        child_tree = nodes[i + 1]
      end

      if child_tree ~= nil then
        table.insert(tree, Tree.Node({ text = v.text, file = v.file, children = child_tree, item_pos = item_pos }))
      else
        table.insert(tree, Tree.Node({ text = v.text, file = v.file, item_pos = item_pos }))
      end

      item_pos = item_pos + 1
    end
  end

  return tree
end

local function node_files(file, parts, node, aux_ids)
  -- aqui.md
  -- vault/index.md
  -- vault/frutas/licuados.md
  -- vault/frutas/liquidos/agua.md
  -- vault/frutas/amargos/cerveza.md

  local aux_node = node

  for i = 1, #parts do
    if i == #parts then
      -- Asignación del archivo en su nodo particular
      table.insert(aux_node, { text = parts[i], file = file })
    else
      -- Asignación del directorio
      if not aux_ids[parts[i]] then
        table.insert(aux_node, { text = parts[i], file = nil })

        aux_ids[parts[i]] = { #aux_node + 1 }
        table.insert(aux_node, {})
      end

      aux_node = aux_node[aux_ids[parts[i]][1]]
      aux_ids = aux_ids[parts[i]]
    end
  end

  return node
end

-- DEPRECATED: Esta función fue reemplazada por node_files
-- local function node_files_v1(file, parts, node)
--   local first_part = parts[1]

--   table.remove(parts, 1)

--   if #parts == 0 then
--     table.insert(node, first_part)
--   else
--     if not node[first_part] then
--       node[first_part] = {}
--     end

--     local child_node = node[first_part]

--     while #parts > 0 do
--       if #parts == 1 then
--         table.insert(child_node, parts[1])
--       else
--         if not child_node[parts[1]] then
--           child_node[parts[1]] = {}
--         end
--       end

--       child_node = child_node[parts[1]]
--       table.remove(parts, 1)
--     end
--   end

--   return node
-- end

local function preview_data(bufnr_preview, root_dir, item)
  local path = string.format('%s/%s', root_dir, item)

  plenary_async.run(function()
    local data = utils.read_file(path)
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
end

local DisplayNui = {}
DisplayNui.__index = DisplayNui

function DisplayNui:init(opts, root_dir, follow_dir)
  follow_dir = string.gsub(follow_dir, '^' .. root_dir .. '/', '')

  local data = {
    root_dir = root_dir,
    opts = opts,
    preview = {
      state = true,
    },
    files = nil,
    follow_dir = follow_dir,
  }

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

  data.files = utils.get_files(data.root_dir, data.opts.filters[data.opts.searching], false)

  setmetatable(data, DisplayNui)

  return data
end

function DisplayNui:mapping_tree(layout, popup_preview, popup_tree, tree)
  popup_tree:map('n', self.opts.keymaps.scroll_preview, function()
    if self.preview.state then
      layout:update(Layout.Box({
        Layout.Box(popup_tree, { size = '100%' }),
      }, { dir = 'col' }))
    else
      layout:update(Layout.Box({
        Layout.Box(popup_preview, { size = '60%' }),
        Layout.Box(popup_tree, { size = '40%' }),
      }, { dir = 'col' }))

      preview_data(popup_preview.bufnr, self.root_dir, tree:get_node().file)
    end

    self.preview.state = not self.preview.state
  end)

  popup_tree:map('n', self.opts.keymaps.menu_down, function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('j', true, false, true), 'n', true)

    if not self.preview.state then
      return
    end

    local item_pos = tree:get_node().item_pos + 1
    local file = nil

    if item_pos > 0 and item_pos <= #tree:get_nodes() then
      file = tree:get_nodes()[item_pos].file

      if file ~= nil then
        preview_data(popup_preview.bufnr, self.root_dir, file)
      else
        vim.api.nvim_buf_set_lines(popup_preview.bufnr, 0, -1, false, {})
      end
    end
  end)

  popup_tree:map('n', self.opts.keymaps.menu_up, function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('k', true, false, true), 'n', true)

    if not self.preview.state then
      return
    end

    local item_pos = tree:get_node().item_pos - 1
    local file = nil

    if item_pos > 0 and item_pos <= #tree:get_nodes() then
      file = tree:get_nodes()[item_pos].file

      if file ~= nil then
        preview_data(popup_preview.bufnr, self.root_dir, file)
      else
        vim.api.nvim_buf_set_lines(popup_preview.bufnr, 0, -1, false, {})
      end
    end
  end)

  popup_tree:map('n', self.opts.keymaps.menu_back, function()
    if _G.linksmd.nui.tree.level > 0 then
      tree:set_nodes(_G.linksmd.nui.tree.parent_files[_G.linksmd.nui.tree.level])
      table.remove(_G.linksmd.nui.tree.parent_files, _G.linksmd.nui.tree.level)
      table.remove(_G.linksmd.nui.tree.breadcrumb, _G.linksmd.nui.tree.level)

      if #_G.linksmd.nui.tree.breadcrumb > 0 then
        popup_tree.border:set_text(
          'top',
          string.format(' %s -> %s ', self.opts.text.menu, table.concat(_G.linksmd.nui.tree.breadcrumb, '/')),
          'left'
        )
      else
        popup_tree.border:set_text('top', string.format(' %s ', self.opts.text.menu), 'left')
      end

      tree:render()

      vim.api.nvim_buf_set_lines(popup_preview.bufnr, 0, -1, false, {})

      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('gg', true, false, true), 'n', true)

      _G.linksmd.nui.tree.level = _G.linksmd.nui.tree.level - 1
    end
  end)

  popup_tree:map('n', self.opts.keymaps.menu_enter, function()
    ---@diagnostic disable-next-line: redefined-local
    local node = tree:get_node()

    table.insert(_G.linksmd.nui.tree.parent_files, tree:get_nodes())
    _G.linksmd.nui.tree.level = _G.linksmd.nui.tree.level + 1
    table.insert(_G.linksmd.nui.tree.breadcrumb, node.text)

    if node.children then
      -- local tree_nodes = node_tree(node.children)
      -- tree:set_nodes(tree_nodes)
      tree:set_nodes(node.children)
      tree:render()

      popup_tree.border:set_text(
        'top',
        string.format(' %s -> %s ', self.opts.text.menu, table.concat(_G.linksmd.nui.tree.breadcrumb, '/')),
        'left'
      )

      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('gg', true, false, true), 'n', true)
    else
      local file = node.file
      print(file)
    end
  end)
end

function DisplayNui:launch()
  vim.cmd('messages clear')

  local nodes = {}
  local node_ids = {}

  for _, file in ipairs(self.files.filtered) do
    local parts = vim.split(file, '/')

    nodes = node_files(file, parts, nodes, node_ids)
  end

  if #nodes == 0 then
    vim.notify(
      string.format('[linksmd] No found notes in this notebook (%s)', self.opts.notebook_main),
      vim.log.levels.WARN,
      { render = 'minimal' }
    )
    return
  end

  local popup_preview = nui_popup(false, false, self.opts.text.preview)
  local popup_tree = nui_popup(true, true, self.opts.text.menu)
  local menu_tree = nui_tree(popup_tree.bufnr)

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
      -- Layout.Box(popup_preview, { size = '60%' }),
      Layout.Box(popup_tree, { size = '40%' }),
      -- Layout.Box(input_file, { size = '20%' }),
    }, { dir = 'col' })
  )

  -- local tree2 = node_tree2(nodes)
  local tree = node_tree(nodes, {})
  if self.follow_dir ~= nil then
    local tree2 = node_tree_follow(tree, vim.split(self.follow_dir, '/'))

    popup_tree.border:set_text(
      'top',
      string.format(' %s -> %s ', self.opts.text.menu, table.concat(_G.linksmd.nui.tree.breadcrumb, '/')),
      'left'
    )

    -- print(#_G.linksmd.nui.tree.parent_files)
    -- print(vim.inspect(_G.linksmd.nui.tree.parent_files[1]))
    -- print(vim.inspect(tree))
    -- menu_tree:set_nodes(_G.linksmd.nui.tree.parent_files[1])
    menu_tree:set_nodes(tree2)
  end

  layout:mount()
  menu_tree:render()

  self:mapping_tree(layout, popup_preview, popup_tree, menu_tree)

  popup_tree:on(event.BufLeave, function()
    popup_preview:unmount()
    popup_tree:unmount()
  end)
end

function DisplayNui:launch2()
  local popup_preview = nui_popup(false, false)
  local menu_links = nui_menu('Linksmd', self.files.filtered_files, popup_preview.bufnr, self.root_dir)

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
      Layout.Box(menu_links, { size = '40%' }),
    }, { dir = 'col' })
  )

  layout:mount()

  menu_links:map('n', self.opts.keymaps.scroll_preview_down, function()
    vim.api.nvim_buf_call(popup_preview.bufnr, function()
      local pos_line = vim.api.nvim_win_get_cursor(0)[1]

      if pos_line < vim.api.nvim_buf_line_count(popup_preview.bufnr) - 10 then
        vim.api.nvim_win_set_cursor(0, { pos_line + 12, 0 })
      end
    end)
  end)

  menu_links:map('n', self.opts.keymaps.scroll_preview_up, function()
    vim.api.nvim_buf_call(popup_preview.bufnr, function()
      local pos_line = vim.api.nvim_win_get_cursor(0)[1]

      if pos_line > 5 then
        if pos_line - 12 < 5 then
          vim.api.nvim_win_set_cursor(0, { 5, 0 })
        else
          vim.api.nvim_win_set_cursor(0, { pos_line - 12, 0 })
        end
      end
    end)
  end)

  menu_links:map('n', self.opts.keymaps.scroll_preview, function()
    if self.preview.state then
      layout:update(Layout.Box({
        Layout.Box(menu_links, { size = '100%' }),
      }, { dir = 'col' }))
    else
      layout:update(Layout.Box({
        Layout.Box(popup_preview, { size = '60%' }),
        Layout.Box(menu_links, { size = '40%' }),
      }, { dir = 'col' }))
    end

    self.preview.state = not self.preview.state
  end)

  menu_links:on(event.BufLeave, function()
    menu_links:unmount()
    popup_preview:unmount()
  end)
end

return DisplayNui
