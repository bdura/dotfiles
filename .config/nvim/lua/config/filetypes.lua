vim.filetype.add({
  extension = { kbd = 'kanata' },
})

vim.filetype.add({
  extension = { wesl = 'wesl' },
})

vim.filetype.add({
  pattern = {
    ['.*/docker%-compose%.ya?ml'] = 'yaml.docker-compose',
    ['.*/compose%.ya?ml'] = 'yaml.docker-compose',
    ['.*/docker%-compose%.[^/]+%.ya?ml'] = 'yaml.docker-compose',
    ['.*/compose%.[^/]+%.ya?ml'] = 'yaml.docker-compose',
  },
})
