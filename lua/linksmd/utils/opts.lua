return {
  notebook_main = vim.fn.expand('~') .. '/test',
  resource = 'notes',
  display_init = 'nui',
  custom = {
    text = {
      preview = nil,
      menu = 'Notas',
    },
    icons = {
      directory = '',
      notes = '',
      books = '',
      images = '',
      sound = '󰎇',
    },
  },
  dir_resources = {
    books = '/books',
    images = '/images',
    sound = '/sound',
  },
  resources = {
    notes = { 'md', 'rmd' },
    books = { 'pdf' },
    images = { 'png', 'jpg', 'jpeg' },
    sound = { 'mp3' },
    buffer = { 'headers', 'urls' },
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
    search_dir = '<M-d>',
    change_searching = '<M-s>',
    switch_manager = '<M-a>',
  },
}
