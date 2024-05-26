return {
  notebook_main = vim.fn.expand('~') .. '/test',
  resource = 'notes',
  display_init = 'nui',
  custom = {
    text = {
      preview = 'Preview',
      menu = 'Notas',
      headers = 'Titulos',
      search_note = 'Buscar Archivo',
      search_dir = 'Buscar Directorio',
      change_searching = 'Nueva Busqueda',
      helper = 'Ayuda',
    },
    icons = {
      directory = '',
      notes = '',
      books = '',
      images = '',
      sounds = '󰎇',
      headers = '󰐣',
    },
  },
  dir_resources = {
    books = '/books',
    images = '/images',
    -- sounds = '/sounds',
  },
  resources = {
    notes = { 'md', 'rmd' },
    books = { 'pdf' },
    images = { 'png', 'jpg', 'jpeg' },
    sounds = { 'mp3' },
    headers = {}, -- No renombrar para no causar posibles conflictos
  },
  flags = {
    notes = 'note',
    books = 'book',
    images = 'img',
    sounds = 'sound',
    headers = '', -- No renombrar para no causar posibles conflictos
  },
  keymaps = {
    menu_enter = { '<cr>', '<tab>' },
    menu_back = { '<bs>', '<s-tab>' },
    menu_down = { 'j', '<M-j>', '<down>' },
    menu_up = { 'k', '<M-k>', '<up>' },
    scroll_preview = '<M-p>',
    scroll_preview_down = '<M-J>',
    scroll_preview_up = '<M-K>',
    search_note = '<M-f>',
    search_dir = '<M-d>',
    change_searching = '<M-s>',
    switch_manager = '<M-a>',
    helper = '?',
    helper_quit = { '<esc>', '<M-q>' },
  },
}
