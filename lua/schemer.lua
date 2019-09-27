colors = require("colors")

-- hi Normal                     guifg=#CCCCCC guibg=NONE    gui=NONE      ctermfg=250
-- hi NonText                    guifg=#6A6A6A guibg=NONE    gui=NONE      ctermfg=008
-- hi Comment                    guifg=#555555 guibg=NONE    gui=NONE      ctermfg=243
-- hi Constant                   guifg=#40BDFF guibg=NONE    gui=NONE      ctermfg=039
-- hi Directory                  guifg=#40BDFF guibg=NONE    gui=NONE      ctermfg=039
-- hi Identifier                 guifg=#787878 guibg=NONE    gui=NONE      ctermfg=246
-- hi PreProc                    guifg=#787878 guibg=NONE    gui=NONE      ctermfg=246
-- hi Special                    guifg=#EFEFEF guibg=NONE    gui=NONE      ctermfg=255
-- hi Statement                  guifg=#CCCCCC guibg=NONE    gui=NONE      ctermfg=250
-- hi Title                      guifg=#CCCCCC guibg=NONE    gui=bold      ctermfg=250
-- hi Type                       guifg=#64B2DB guibg=NONE    gui=NONE      ctermfg=039
-- hi SpecialKey                 guifg=#40BDFF guibg=NONE    gui=NONE      ctermfg=039
-- hi Conditional                guifg=#64B2DB guibg=NONE    gui=NONE      ctermfg=039
-- hi Operator                   guifg=#AAAAAA guibg=NONE    gui=NONE      ctermfg=246
-- hi Exception                  guifg=#64B2DB guibg=NONE    gui=NONE      ctermfg=039
-- hi Label                      guifg=#64B2DB guibg=NONE    gui=NONE      ctermfg=039
-- hi Repeat                     guifg=#64B2DB guibg=NONE    gui=NONE      ctermfg=039
-- hi Keyword                    guifg=#64B2DB guibg=NONE    gui=NONE      ctermfg=039
-- hi String                     guifg=#5697B8 guibg=NONE    gui=NONE      ctermfg=039
-- hi Character                  guifg=#40BDFF guibg=NONE    gui=NONE      ctermfg=039
-- hi Boolean                    guifg=#40BDFF guibg=NONE    gui=NONE      ctermfg=039
-- hi Number                     guifg=#40BDFF guibg=NONE    gui=NONE      ctermfg=039
-- hi Function                   guifg=#EFEFEF guibg=NONE    gui=NONE      ctermfg=255
-- hi Underlined                 guifg=#CCCCCC guibg=NONE    gui=underline ctermfg=250

function SchemerGenerate()
  local c = colors.new(130, .8, 0.3)
  vim.api.nvim_command("hi Normal guifg="..tostring(c))
end
