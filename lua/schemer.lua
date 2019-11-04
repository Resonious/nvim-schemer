colors = require("colors")


-- These commands are applied to every generated theme
local constant_cmds = {
  { purpose="scheme-name" },
  "set    termguicolors",
  "hi     clear",
  "syntax reset",
  "hi Underlined                 gui=underline",
  "hi ColorColumn                guifg=#CCCCCC guibg=#292929 gui=bold      ctermfg=250   ctermbg=008",
  "hi Pmenu                      guifg=#EFEFEF guibg=#0C0C0C gui=NONE      ctermfg=255   ctermbg=000",
  "hi PmenuSel                   guifg=#EFEFEF guibg=#40BDFF gui=NONE      ctermfg=255   ctermbg=039",
  "hi PmenuThumb                 guifg=#EFEFEF guibg=#40BDFF gui=NONE      ctermfg=255   ctermbg=039",
  "hi StatusLine                 guifg=#CCCCCC guibg=NONE    gui=NONE      ctermfg=250   ctermbg=NONE",
  "hi StatusLineNC               guifg=#CCCCCC guibg=NONE    gui=NONE      ctermfg=250   ctermbg=NONE",
  "hi CursorLineNr               guifg=#CCCCCC guibg=#292929 gui=bold      ctermfg=255   ctermbg=NONE    cterm=bold",
  "hi TabLine                    guifg=#CCCCCC guibg=NONE    gui=NONE      ctermfg=250   ctermbg=NONE    cterm=NONE",
  "hi TabLineFill                guifg=#CCCCCC guibg=NONE    gui=NONE      ctermfg=250   ctermbg=NONE    cterm=NONE",
  "hi FoldColumn                 guifg=#0C0C0C guibg=#40BDFF gui=NONE      ctermfg=235   ctermbg=039",
  "hi Folded                     guifg=#0C0C0C guibg=#40BDFF gui=NONE      ctermfg=235   ctermbg=039",
  "hi LineNr                     guifg=#6A6A6A guibg=#0F0F0F gui=NONE      ctermfg=245   ctermbg=000",
  "hi SignColumn                 guifg=#EFEFEF guibg=NONE    gui=NONE      ctermfg=255   ctermbg=NONE",
  "hi VertSplit                  guifg=#AAAAAA guibg=NONE    gui=NONE      ctermfg=246   ctermbg=000",
  "hi WildMenu                   guifg=#CCCCCC guibg=#292929 gui=NONE      ctermfg=250   ctermbg=008",
  "hi OverLength                 guifg=NONE    guibg=#20272F gui=NONE      ctermfg=NONE  ctermbg=018",

  "hi PmenuSel                   guifg=#EFEFEF guibg=#FF3D23 gui=NONE      ctermfg=255   ctermbg=244",
  "hi PmenuThumb                 guifg=#EFEFEF guibg=#FF3D23 gui=NONE      ctermfg=255   ctermbg=244",
  "hi FoldColumn                 guifg=#0C0C0C guibg=#FF3D23 gui=NONE      ctermfg=235   ctermbg=244",
  "hi Folded                     guifg=#0C0C0C guibg=#FF3D23 gui=NONE      ctermfg=235   ctermbg=244",
  "hi OverLength                 guifg=NONE    guibg=#641900 gui=NONE      ctermfg=NONE  ctermbg=052"
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
local function apply_color(cmds, color, ...)
  local tags = {...}

  for _, tag in ipairs(tags) do
    table.insert(
      cmds,
      "hi "..tag..
      " guifg="..tostring(color)..
      " guibg=NONE gui=NONE ctermfg=250"
    )
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
local function biased_random(bias)
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
local function choose_from(...)
  local options = {...}
  return options[math.random(#options)]
end

local function lighten_until_visible(color)
  local count = 0
  while not is_visible(color) do
    color = color:lighten_by(1.1)
    count = count + 1
  end

  return color, count
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
  local lighten_count
  schemer_cmds = {}

  repeat
    messages = {}

    -- This color is usually find for comments
    comment = colors.new("#858585")

    -- Error colors
    info    = colors.new("#00FFFF")
    warning = colors.new("#FF8D00")
    error   = colors.new("#FF0000")

    -- We will always use this primary color
    primary = colors.new(math.random(360), clamp(math.random() + 0.25), biased_random(0.5))

    ---- HEURISTICS AND TWEAKS FOR PRIMARY ----
    -- Can lighten the primary color if it's too dark
    primary, lighten_count = lighten_until_visible(primary)
    if lighten_count >= 1 then
      table.insert(messages, "lightened primary color "..lighten_count.." times to make it visible")
    end

    ---- PICKING SECONDARY COLORS ----
    -- Choose how to derive the non-primary colros
    local derivation = choose_from('complementary', 'neighboring')
    table.insert(messages, "selected "..derivation.." colors")

    if derivation == 'complementary' then
      local tints = primary:tints(5)
      literals   = primary:complementary()
      secondary = tints[4]
      tertiary  = tints[2]

      literals, lighten_count = lighten_until_visible(literals)
      if lighten_count >= 1 then
        table.insert(messages, "lightened complement "..lighten_count.." times to make it visible")
      end

    elseif derivation == 'neighboring' then
      literals = primary:lighten_by('0.78')
      secondary, tertiary = primary:neighbors(60)

      secondary, lighten_count = lighten_until_visible(secondary)
      if lighten_count >= 1 then
        table.insert(messages, "lightened secondary "..lighten_count.." times to make it visible")
      end

      tertiary, lighten_count = lighten_until_visible(tertiary)
      if lighten_count >= 1 then
        table.insert(messages, "lightened tertiary "..lighten_count.." times to make it visible")
      end
    end


    -- Come up with a good comment color
    if math.random() < 0.6 then
      next1, next2 = tertiary:triadic()
      comment = choose_from(tertiary, next1, next2):lighten_to(0.48):desaturate_to(0.2)
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

  apply_color(schemer_cmds, colors.new("#6A6A6A"), "NonText")
  apply_color(schemer_cmds, colors.new("#EFEFEF"), "Special", "Function")

  apply_color(schemer_cmds, primary, "Repeat", "Conditional", "Type", "Constant", "Directory", "SpecialKey")
  apply_color(schemer_cmds, literals, "String", "Number", "Character", "Boolean")
  apply_color(schemer_cmds, secondary, "Exception", "Label", "Keyword")
  apply_color(schemer_cmds, tertiary, "PreProc", "Identifier", "Operator", "Statement")
  apply_color(schemer_cmds, uncolored, "Normal", "Title", "Underlined")

  apply_color(schemer_cmds, comment, "Comment")
  apply_color(schemer_cmds, error,   "NeomakeVirtualtextError")
  apply_color(schemer_cmds, warning, "NeomakeVirtualtextWarning")
  apply_color(schemer_cmds, info,    "NeomakeVirtualtextInfo")

  local apply_cmd = function(cmd)
    if     type(cmd)   == 'string'      then vim.api.nvim_command(cmd)
    elseif cmd.purpose == 'scheme-name' then vim.api.nvim_command("let g:colors_name = 'schemer'")
    end
  end

  for _, cmd in ipairs(constant_cmds) do apply_cmd(schemer_cmds) end
  for _, cmd in ipairs(schemer_cmds)  do apply_cmd(schemer_cmds) end

  print('Run :SchemerSave "myschemename" to save your colorscheme.')
end


-- Gotta be able to save your theme.
function SchemerSave(theme_name)
  if #schemer_cmds == 0 then
    print("Run :Schemer to generate a theme first!")
  end

  if theme_name == nil then theme_name = 'schemer' end

  file = io.open(schemer_plugindir.."/colors/"..theme_name..".vim", "w")
  file:write("\" Generated by Schemer\n")

  local apply_cmd = function(cmd)
    if type(cmd) == 'table' then
      if cmd.purpose == 'scheme-name' then file:write("let g:colors_name = '"..theme_name.."'")
      else print("Schemer bug! unknown cmd purpose: "..cmd.purpose)
      end
    else
      file:write(cmd)
    end
    file:write("\n")
  end

  for _, cmd in ipairs(constant_cmds) do apply_cmd(cmd) end
  for _, cmd in ipairs(schemer_cmds)  do apply_cmd(cmd) end
  file:close()

  print("Run 'colorscheme "..theme_name.."' (perhaps put it in your init.vim) to load your saved theme.")
end
