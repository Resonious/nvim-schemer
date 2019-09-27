colors = require("colors")


-- Assume a black background
local background = colors.new(0, 0, 0)
-- Minimum acceptable contrast between text and background
local minimum_contrast = 6.0
-- "Uncolored" text color
local uncolored = colors.new("#CCCCCC")

math.randomseed(os.time())


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
local function apply_color(color, ...)
  local tags = {...}

  for _, tag in ipairs(tags) do
    vim.api.nvim_command(
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


-- Entrypoint from vim command.
-- Generates and applies a random colorscheme.
function SchemerGenerate()
  ----
  ---- Random generation ----
  ----

  local primary, strings, secondary, tertiary, comment
  local retry_count = -1
  local messages = {}

  repeat
    messages = {}

    -- This color is usually find for comments
    comment = colors.new("#858585")

    -- We will always use this primary color
    primary = colors.new(math.random(360), clamp(math.random() + 0.25), biased_random(0.5))

    ---- HEURISTICS AND TWEAKS FOR PRIMARY ----
    -- Can lighten the primary color if it's too dark
    local lighten_count = 0
    while not is_visible(primary) do
      primary = primary:lighten_by(1.1)
      lighten_count = lighten_count + 1
    end

    if lighten_count >= 1 then
      table.insert(messages, "lightened primary color "..lighten_count.." times to make it visible")
    end

    ---- PICKING SECONDARY COLORS ----
    -- Choose how to derive the non-primary colros
    local derivation = choose_from('complementary', 'neighboring')

    if derivation == 'complementary' then
      local tints = primary:tints(5)
      strings   = primary:complementary()
      secondary = tints[4]
      tertiary  = tints[2]

    elseif derivation == 'neighboring' then
      strings = primary:lighten_by('0.78')
      secondary, tertiary = primary:neighbors(60)
    end

    table.insert(messages, "selected "..derivation.." colors")


    -- Come up with a good comment color
    if math.random() < 0.6 then
      next1, next2 = tertiary:triadic()
      comment = choose_from(tertiary, next1, next2):lighten_to(0.4):desaturate_to(0.2)
      table.insert(messages, "tinted comments")
    end


    retry_count = retry_count + 1
  until is_visible(primary, strings, secondary, tertiary)


  -----------------------------------------------------------
  local function hsl(c)
    return "("..c.H..", "..c.S..", "..c.L..")"
  end
  local plugindir = string.match(debug.getinfo(1,'S').source, '^@(.+)/lua/schemer.lua$')

  file = io.open(plugindir.."/last-generated.txt", "w")
  file:write("------------------------------------------------------\n")
  file:write("primary   = "..tostring(primary).." "..hsl(primary).." cr: "..contrast_ratio(primary, background)..":1\n")
  file:write("strings   = "..tostring(strings).." "..hsl(strings).." cr: "..contrast_ratio(strings, background)..":1\n")
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

  vim.api.nvim_set_option("termguicolors", true)

  vim.api.nvim_command("hi clear")
  vim.api.nvim_command("syntax reset")
  vim.api.nvim_command("let g:colors_name = 'schemer'")

  apply_color(colors.new("#6A6A6A"), "NonText")
  apply_color(colors.new("#EFEFEF"), "Special", "Function")

  apply_color(primary, "Constant", "Directory", "SpecialKey", "Character", "Boolean")
  apply_color(strings, "String", "Number")
  apply_color(secondary, "Type", "Conditional", "Exception", "Label", "Repeat", "Keyword")
  apply_color(tertiary, "PreProc", "Identifier", "Operator")
  apply_color(uncolored, "Normal", "Statement", "Title", "Underlined")
  apply_color(comment, "Comment")

  vim.api.nvim_command("hi Underlined gui=underline")
end


function SchemerSave()
  -- TODO
end


function SchemerLoad()
  -- TODO
end
