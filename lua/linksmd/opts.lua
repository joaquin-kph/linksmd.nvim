return {
  notebook_main = vim.fn.expand('~') .. '/test',
  searching = 'markdown',
  display = 'nui', -- TODO: Eliminar en un futuro, ya que la idea era hacer tambien una version con telescope pero por cuetiones de tiempo no me lo permite
  text = {
    preview = nil,
    menu = 'Notas',
  },
  filters = {
    markdown = { 'md', 'rmd' },
    books = { 'pdf' },
    images = { 'png', 'jpg' },
    sound = { 'mp3' },
    urls = { 'https', 'http' },
  },
  keymaps = {
    menu_enter = { '<cr>', '<tab>' },
    menu_back = { '<bs>', '<s-tab>' },
    menu_down = { 'j', '<M-j>', '<down>' },
    menu_up = { 'k', '<M-k>', '<up>' },
    scroll_preview = '<M-p>',
    scroll_preview_down = '<M-d>',
    scroll_preview_up = '<M-u>',
    search_file = '<M-f>',
  },
}
