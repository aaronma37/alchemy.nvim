fun! Alchemy()
    " dont forget to remove this one....
    lua for k in pairs(package.loaded) do if k:match("^alchemy") then package.loaded[k] = nil end end
    lua require("alchemy")
endfun

command! -nargs=* Alchemy exe 'lua package.loaded.test = nil' | lua require'alchemy'.test(<args>)
augroup Alchemy
  autocmd!
augroup END
