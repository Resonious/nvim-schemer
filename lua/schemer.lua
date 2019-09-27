colors = require("colors")


-- Assume a black background
local background = colors.new(0, 0, 0)
-- Minimum acceptable contrast between text and background
local minimum_contrast = 5.0
-- "Uncolored" text color
local uncolored = colors.new("#CCCCCC")


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


local function colors_are_visible(...)
  local colors = {...}
  for _, color in ipairs(colors) do
    if contrast_ratio(color, background) < minimum_contrast then
      return false
    end
  end
  return true
end


-- Entrypoint from vim command.
-- Generates and applies a random colorscheme.
function SchemerGenerate()
  ----
  ---- Setup / configuration ----
  ----

  -- We only support gui colors for now
  vim.api.nvim_set_option("termguicolors", true)


  ----
  ---- Random generation ----
  ----
  -- TODO we'll need to retry this, so it'll probably get factored out at some point

  local primary, strings, secondary, tertiary
  local retry_count = -1 -- TODO debugging info

  repeat
    -- We will always use this primary color
    primary = colors.new(math.random(360), clamp(math.random() + 0.5), biased_random(0.5))
    -- Color for strings
    strings   = primary:complementary()
    -- Secondary color
    secondary = primary:tints(6)[6]
    -- Tertiary
    tertiary  = primary:tints(5)[3]

    retry_count = retry_count + 1
  until colors_are_visible(primary, strings, secondary, tertiary)


  -- TODO begin debuggin file crap
  local function hsl(c)
    return "("..c.H..", "..c.S..", "..c.L..")"
  end
  file = io.open ("/home/nigel/.config/nvim/test.log", "w")
  file:write("------------------------------------------------------\n")
  file:write("primary   = "..tostring(primary).." ("..hsl(primary).." cr: "..contrast_ratio(primary, background)..":1\n")
  file:write("strings   = "..tostring(strings).." ("..hsl(strings).." cr: "..contrast_ratio(strings, background)..":1\n")
  file:write("secondary = "..tostring(secondary).." ("..hsl(secondary).." cr: "..contrast_ratio(secondary, background)..":1\n")
  file:write("tertiary  = "..tostring(tertiary).." ("..hsl(tertiary).." cr: "..contrast_ratio(tertiary, background)..":1\n")
  file:write("retried "..retry_count.." times\n")
  file:write("------------------------------------------------------\n")
  file:close()
  -- TODO end debuggin file crap



  ----
  ---- Applying the theme ----
  ----

  vim.api.nvim_command("hi clear")
  vim.api.nvim_command("syntax reset")
  vim.api.nvim_command("let g:colors_name = 'schemed'")

  apply_color(colors.new("#6A6A6A"), "NonText")
  apply_color(colors.new("#EFEFEF"), "Special", "Function")
  apply_color(colors.new("#606060"), "Comment")

  apply_color(primary, "Constant", "Directory", "SpecialKey", "Character", "Boolean")
  apply_color(strings, "String", "Number")
  apply_color(secondary, "Type", "Conditional", "Exception", "Label", "Repeat", "Keyword")
  apply_color(tertiary, "PreProc", "Identifier", "Operator")
  apply_color(uncolored, "Normal", "Statement", "Title", "Underlined")

  vim.api.nvim_command("hi Underlined gui=underline")
end
