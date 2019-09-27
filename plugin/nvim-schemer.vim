lua require("schemer")

command Schemer lua SchemerGenerate()
command SchemerSave lua SchemerSave()
command SchemerLoad colorscheme schemer

command SchemerCrazy call jobstart('while sleep 0.1; do echo "."; done', {'on_stdout':{-> luaeval('SchemerGenerate()')}})
