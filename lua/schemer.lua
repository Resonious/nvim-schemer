colors = require("colors")

local fzf_colors_str = [[let g:fzf_colors = {
    'fg':      ['fg', 'Normal'],
    'bg':      ['bg', 'Normal'],
    'hl':      ['fg', 'schemerComment'],
    'fg+':     ['fg', 'Normal'],
    'bg+':     ['bg', 'Normal'],
    'hl+':     ['fg', 'schemerLiterals'],
    'info':    ['fg', 'schemerTertiary'],
    'border':  ['fg', 'Ignore'],
    'prompt':  ['fg', 'schemerPrimary'],
    'pointer': ['fg', 'schemerSecondary'],
    'marker':  ['fg', 'schemerSecondary'],
    'spinner': ['fg', 'schemerSecondary'],
    'header':  ['fg', 'schemerComment'] }]]
local fzf_colors_cmd, _ = fzf_colors_str:gsub("\n", '')

-- These commands are applied to every generated theme
local constant_cmds = {
  { purpose="scheme-name" },
  "set    termguicolors",
  "hi     clear",
  "syntax reset",
  "hi Underlined                 gui=underline",
  "hi ColorColumn                guifg=#CCCCCC guibg=#292929 gui=bold      ctermfg=250   ctermbg=008",
  "hi StatusLine                 guifg=#CCCCCC guibg=NONE    gui=NONE      ctermfg=250   ctermbg=NONE",
  "hi StatusLineNC               guifg=#CCCCCC guibg=NONE    gui=NONE      ctermfg=250   ctermbg=NONE",
  "hi CursorLineNr               guifg=#CCCCCC guibg=#292929 gui=bold      ctermfg=255   ctermbg=NONE    cterm=bold",
  "hi TabLine                    guifg=#CCCCCC guibg=NONE    gui=NONE      ctermfg=250   ctermbg=NONE    cterm=NONE",
  "hi TabLineFill                guifg=#CCCCCC guibg=NONE    gui=NONE      ctermfg=250   ctermbg=NONE    cterm=NONE",
  "hi LineNr                     guifg=#6A6A6A guibg=#0F0F0F gui=NONE      ctermfg=245   ctermbg=000",
  "hi SignColumn                 guifg=#EFEFEF guibg=NONE    gui=NONE      ctermfg=255   ctermbg=NONE",
  "hi VertSplit                  guifg=#AAAAAA guibg=NONE    gui=NONE      ctermfg=246   ctermbg=000",
  "hi WildMenu                   guifg=#CCCCCC guibg=#292929 gui=NONE      ctermfg=250   ctermbg=008",
  "hi OverLength                 guifg=NONE    guibg=#20272F gui=NONE      ctermfg=NONE  ctermbg=018",

  "hi OverLength                 guifg=NONE    guibg=#641900 gui=NONE      ctermfg=NONE  ctermbg=052",

  "hi CursorColumn               guifg=NONE    guibg=#292929 gui=NONE      ctermfg=NONE  ctermbg=008     cterm=NONE",
  "hi CursorLine                 guifg=NONE    guibg=#292929 gui=NONE      ctermfg=NONE  ctermbg=008     cterm=NONE",
  "hi Visual                     guifg=#EFEFEF guibg=#515151 gui=NONE      ctermfg=255   ctermbg=008",
  "hi VisualNOS                  guifg=#EFEFEF guibg=#515151 gui=NONE      ctermfg=255   ctermbg=008",
  "hi Todo                       guifg=#DEDD5A guibg=NONE    gui=bold      ctermfg=226   ctermbg=NONE",

  "hi link                       markdownLinkText            PreProc",
  "hi link                       markdownHeadingDelimiter    Number",
  "hi link                       markdownHeader              Number",
  "hi link                       markdownInlineCode          PreProc",
  "hi link                       markdownFencedCodeBlock     PreProc",
  "hi link                       markdownCodeBlock           PreProc",

  fzf_colors_cmd
}


-- Assume a black background
local background = colors.new(0, 0, 0)
-- Minimum acceptable contrast between text and background
local minimum_contrast = 6.0
-- "Uncolored" text color
local uncolored = colors.new("#CCCCCC")

math.randomseed(os.time())
schemer_plugindir = string.match(debug.getinfo(1,'S').source, '^@(.+)/lua/schemer.lua$')
schemer_cmds = {}


-- Get r, g, b floats out of a color.
local function rgb(color)
  local hex = color:to_rgb()
  hex = hex:gsub("#", "")
  return tonumber("0x"..hex:sub(1,2)) / 255.0,
         tonumber("0x"..hex:sub(3,4)) / 255.0,
         tonumber("0x"..hex:sub(5,6)) / 255.0
end


-- Gets the relative luminance of a color based on
-- https://www.w3.org/TR/WCAG20/#relativeluminancedef.
local function relative_luminance(color)
  local function l(c)
    if c <= 0.03928 then
      return c/12.92
    else
      return ((c+0.055)/1.055) ^ 2.4
    end
  end
  local cr, cg, cb = rgb(color)
  local r, g, b    = l(cr), l(cg), l(cb)

  return 0.2126 * r + 0.7152 * g + 0.0722 * b
end


-- Gets contrast ratio between two colors based on
-- https://medium.muz.li/the-science-of-color-contrast-an-expert-designers-guide-33e84c41d156.
--
-- Returns a value between 1 and 21 (hopefully)
local function contrast_ratio(color1, color2)
  l1, l2 = relative_luminance(color1), relative_luminance(color2)

  ratio = (l1+0.05) / (l2+0.05)
  if ratio < 1.0 then
    return 1.0 / ratio
  else
    return ratio
  end
end

-- TODO account for cterm?

-- Creates new Schemer-namespaced color group with the given color
local function declare_color(cmds, name, color)
  table.insert(
    cmds,
    "hi schemer"..name..
    " guifg="..tostring(color)..
    " guibg=NONE gui=NONE ctermfg=250"
  )
end

local function declare_colort(cmds, name, color)
  local settings = ""

  if not color['gui'] then color['gui'] = 'NONE' end

  for key,value in pairs(color) do
    settings = settings.." "..key.."="..tostring(value)
  end
  table.insert(cmds, "hi schemer"..name..settings)
end

-- Applies a color directly without the schemer namespace
local function apply_colort(cmds, color, ...)
  local tags = {...}
  local settings = ""

  if not color['gui'] then color['gui'] = 'NONE' end

  for key,value in pairs(color) do
    settings = settings.." "..key.."="..tostring(value)
  end

  for _, tag in ipairs(tags) do
    table.insert(cmds, "hi "..tag..settings)
  end
end

-- Links all of the later arguments to groupname
local function link_color(cmds, groupname, ...)
  local tags = {...}

  for _, tag in ipairs(tags) do
    table.insert(cmds, "hi! link "..tag.." schemer"..groupname)
  end
end


-- You know what this is
local function clamp(number)
  if number > 1.0 then return 1.0 end
  if number < 0.0 then return 0.0 end
  return number
end


-- You know what this is
local function lerp(number, goal, amount)
  if number > goal then
    number = number - amount
    if number < goal then number = goal end
  else
    number = number + amount
    if number > goal then number = goal end
  end
  return number
end


-- Can make a random number, biased towards the argument
local function biased_random(bias, adjust)
  local initial = math.random()
  local adjust  = math.random()
  return lerp(initial, bias, adjust)
end


-- Only returns true when all of the passed colors are visible
-- compared to `background`.
local function is_visible(...)
  local colors = {...}
  for _, color in ipairs(colors) do
    if contrast_ratio(color, background) < minimum_contrast then
      return false
    end
  end
  return true
end


-- Select randomly from an unweighted list
local function choose_from_table(t)
  return t[math.random(#t)]
end
local function choose_from(...)
  local options = {...}
  return choose_from_table(options)
end

local function lighten_until_visible(color, name, messages)
  local count = 0
  while not is_visible(color) do
    color = color:lighten_by(1.1)
    count = count + 1
  end

  if count >= 1 then
    table.insert(messages, "lightened "..name.." "..count.." times to make it visible")
  end

  return color
end


function for_each_schemer_cmd(callback)
  callback({ purpose = "comment", content = "Constants"})
  for _, cmd in ipairs(constant_cmds) do callback(cmd) end

  callback({ purpose = "comment", content = "Generated values"})
  for _, cmd in ipairs(schemer_cmds)  do callback(cmd) end
end


-- Entrypoint from vim command.
-- Generates and applies a random colorscheme.
function SchemerGenerate()
  ----
  ---- Random generation ----
  ----

  local primary, literals, secondary, tertiary, comment
  local error, warning, info
  local retry_count = -1
  local messages = {}
  schemer_cmds = {}

  repeat
    messages = {}

    -- This color is usually fine for comments
    comment = colors.new("#858585")
    panel   = colors.new("#222222")

    -- Error colors
    info    = colors.new("#00FFFF")
    warning = colors.new("#FF8D00")
    error   = colors.new("#FF0000")

    -- We will always use this primary color
    primary = colors.new(math.random(360), clamp(math.random() + 0.22), biased_random(0.5, 0.5))

    ---- HEURISTICS AND TWEAKS FOR PRIMARY ----
    -- Can lighten the primary color if it's too dark
    primary = lighten_until_visible(primary, "primary", messages)

    ---- PICKING SECONDARY COLORS ----
    -- Choose how to derive the non-primary colros
    local derivation = choose_from('complementary', 'neighboring', 'nearby')
    table.insert(messages, "selected "..derivation.." colors")

    if derivation == 'complementary' then
      local tints = primary:tints(5)
      literals    = primary:complementary()
      secondary   = tints[4]
      tertiary    = tints[2]

      literals    = lighten_until_visible(literals, "compliment", messages)

    elseif derivation == 'neighboring' then
      literals = primary:lighten_by('0.78')
      if math.random() < 0.5 then
        tertiary, secondary = primary:neighbors(60)
      else
        secondary, tertiary = primary:neighbors(60)
      end

      secondary = lighten_until_visible(secondary, "secondary", messages)
      tertiary  = lighten_until_visible(tertiary, "tertiary", messages)

    elseif derivation == 'nearby' then
      secondary, tertiary = primary:neighbors(30)
      literals  = choose_from(secondary:hue_offset(30), tertiary:hue_offset(-30))

      secondary = lighten_until_visible(secondary, "secondary", messages)
      tertiary  = lighten_until_visible(tertiary, "tertiary", messages)
      literals  = lighten_until_visible(literals, "literals", messages)
    end


    -- Come up with a good comment color
    if math.random() < 0.6 then
      next1, next2 = tertiary:triadic()
      comment = choose_from(tertiary, next1, next2):lighten_to(0.48):desaturate_to(0.2)
      panel   = comment:lighten_to(0.15)
      table.insert(messages, "tinted comments")
    end


    retry_count = retry_count + 1
  until is_visible(primary, literals, secondary, tertiary)


  -----------------------------------------------------------
  local function hsl(c)
    return "("..c.H..", "..c.S..", "..c.L..")"
  end
  file = io.open(schemer_plugindir.."/last-generated.txt", "w")
  file:write("------------------------------------------------------\n")
  file:write("primary   = "..tostring(primary).." "..hsl(primary).." cr: "..contrast_ratio(primary, background)..":1\n")
  file:write("literals  = "..tostring(literals).." "..hsl(literals).." cr: "..contrast_ratio(literals, background)..":1\n")
  file:write("secondary = "..tostring(secondary).." "..hsl(secondary).." cr: "..contrast_ratio(secondary, background)..":1\n")
  file:write("tertiary  = "..tostring(tertiary).." "..hsl(tertiary).." cr: "..contrast_ratio(tertiary, background)..":1\n")
  file:write("retried "..retry_count.." times\n")
  for _, msg in ipairs(messages) do file:write(msg.."\n") end
  file:write("------------------------------------------------------\n")
  file:close()
  -----------------------------------------------------------


  ----
  ---- Applying the theme ----
  ----

  declare_color(schemer_cmds, "DarkGray",   colors.new("#6A6A6A"))
  declare_color(schemer_cmds, "MediumGray", colors.new("#EFEFEF"))
  declare_color(schemer_cmds, "Uncolored",  uncolored)

  declare_color(schemer_cmds, "Primary",    primary)
  declare_color(schemer_cmds, "Secondary",  secondary)
  declare_color(schemer_cmds, "Tertiary",   tertiary)
  declare_color(schemer_cmds, "Literals",   literals)
  declare_color(schemer_cmds, "Comment",    comment)

  declare_colort(schemer_cmds, "Panel",     { guifg=uncolored, guibg=panel })
  declare_colort(schemer_cmds, "PrimaryBg", { guifg="#0C0C0C", guibg=primary })

  apply_colort(schemer_cmds, { guifg=panel, guibg="#DFDFDF" }, "Cursor", "CursorIM")
  apply_colort(schemer_cmds, { guifg=panel, guibg=primary }, "FoldColumn", "Folded")
  apply_colort(schemer_cmds, { guifg=primary, guibg=panel, gui="bold,underline" }, "MatchParen")
  apply_colort(schemer_cmds, { guifg="#0C0C0C", guibg=literals:lighten_to(0.75) }, "Search")
  apply_colort(schemer_cmds, { guifg="#0C0C0C", guibg=literals:lighten_to(0.95) }, "IncSearch")

  declare_color(schemer_cmds, "Error",   error)
  declare_color(schemer_cmds, "Warning", warning)
  declare_color(schemer_cmds, "Info",    info)

  link_color(schemer_cmds, "DarkGray",   "NonText")
  link_color(schemer_cmds, "MediumGray", "Special", "Function")
  link_color(schemer_cmds, "Panel",      "Pmenu")
  link_color(schemer_cmds, "PrimaryBg",  "PmenuSel", "PmenuThumb")

  link_color(schemer_cmds, "Primary",   "Repeat", "Conditional", "Type", "Constant", "Directory", "SpecialKey")
  link_color(schemer_cmds, "Literals",  "String", "Number", "Character", "Boolean")
  link_color(schemer_cmds, "Secondary", "Exception", "Label", "Keyword")
  link_color(schemer_cmds, "Tertiary",  "PreProc", "Identifier", "Operator", "Statement")
  link_color(schemer_cmds, "Uncolored", "Normal", "Title", "Underlined")

  link_color(schemer_cmds, "Comment", "Comment")
  link_color(schemer_cmds, "Error",   "NeomakeVirtualtextError", "Error")
  link_color(schemer_cmds, "Warning", "NeomakeVirtualtextWarning")
  link_color(schemer_cmds, "Info",    "NeomakeVirtualtextInfo")

  for_each_schemer_cmd(function(cmd)
    if     type(cmd)   == 'string'      then vim.api.nvim_command(cmd)
    elseif cmd.purpose == 'scheme-name' then vim.api.nvim_command("let g:colors_name = 'schemer'")
    end
  end)

  print('Run :SchemerSave "myschemename" to save your colorscheme.')
end


-- Gotta be able to save your theme.
function SchemerSave(theme_name)
  if #schemer_cmds == 0 then
    print("Run :Schemer to generate a theme first!")
  end

  if theme_name == nil then theme_name = 'schemer' end

  file = io.open(schemer_plugindir.."/colors/"..theme_name..".vim", "w")
  file:write("\"\n")
  file:write("\" Generated by Schemer\n")
  file:write("\"\n\n")

  for_each_schemer_cmd(function(cmd)
    if type(cmd) == 'table' then
      if cmd.purpose == 'scheme-name' then file:write("let g:colors_name = '"..theme_name.."'")
      elseif cmd.purpose == 'comment' then file:write("\" "..cmd.content)
      else print("Schemer bug! unknown cmd: ", cmd)
      end
    else
      file:write(cmd)
    end
    file:write("\n")
  end)

  file:close()

  print("Run 'colorscheme "..theme_name.."' (perhaps put it in your init.vim) to load your saved theme.")
end
