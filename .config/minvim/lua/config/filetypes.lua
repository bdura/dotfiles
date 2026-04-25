vim.filetype.add({
  extension = {
    env = 'dotenv',
  },
  filename = {
    ['.env'] = 'dotenv',
  },
})

vim.filetype.add({
  extension = { kbd = 'kanata' },
})

vim.filetype.add({
  extension = { wesl = 'wgsl' },
})
