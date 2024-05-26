local Tree = require('nui.tree')
local plenary_async = require('plenary.async')
local ufiles = require('linksmd.utils.files')

local M = {}

M.node_tree_follow = function(tree, follow_dir, final_tree)
  if #follow_dir == 0 then
    return final_tree
  end

  for i, v in ipairs(tree) do
    if v.text_raw == follow_dir[1] then
      table.remove(follow_dir, 1)

      table.insert(_G.linksmd.nui.tree.parent_files, tree)
      _G.linksmd.nui.tree.level = _G.linksmd.nui.tree.level + 1
      table.insert(_G.linksmd.nui.tree.breadcrumb, v.text_raw)

      if tree[i].children then
        final_tree = M.node_tree_follow(tree[i].children, follow_dir, tree[i].children)
      end
      break
    end
  end

  return final_tree
end

M.node_tree = function(nodes, tree, icons_tree)
  local item_pos = 1

  local icon_dir = icons_tree[1] or nil
  local icon_resource = icons_tree[2] or nil

  for i, v in ipairs(nodes) do
    if #v == 0 then
      local child_tree = nil

      if nodes[i + 1] and #nodes[i + 1] > 0 then
        child_tree = M.node_tree(nodes[i + 1], {}, icons_tree)
      end

      if child_tree ~= nil then
        -- table.insert(tree, { DIR = v.text, children = child_tree })
        table.insert(
          tree,
          Tree.Node({
            text = string.format('%s%s', icon_dir ~= nil and icon_dir .. '  ' or '', v.text),
            text_raw = v.text,
            file = v.file,
            children = child_tree,
            item_pos = item_pos,
          })
        )
      else
        -- table.insert(tree, { FILE = v.text })
        table.insert(
          tree,
          Tree.Node({
            text = string.format('%s%s', icon_resource ~= nil and icon_resource .. '  ' or '', v.text),
            text_raw = v.text,
            file = v.file,
            item_pos = item_pos,
          })
        )
      end

      item_pos = item_pos + 1
    end
  end

  return tree
end

M.node_files = function(file, parts, node, aux_ids)
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

M.preview_data = function(root_dir, item, callback)
  print('ROOT', root_dir, 'FILE', item)
  if item == nil then
    return
  end

  local path = string.format('%s/%s', root_dir, item)
  print('PATH', path)
  plenary_async.run(function()
    local data = ufiles.read_file(path)
    local text = vim.split(data and data or '', '\n')

    vim.schedule(function()
      callback(text)
    end)
  end)
end

return M
