local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'

local spacing = 2

local title_h = 10

local palette_width = 27
local palette_height = 77
local palette_border_color = 16

local toolbar_width = 16+2*spacing

local palette_selector_height = 80+2*spacing

local sprite_w, sprite_h = 128, 128

function build_palette_colors()
  local colors = {}

  local col_w, col_h = 10, 10
  local x, y = spacing, spacing

  local bc = palette_border_color

  local selected = 8

  for i=0,15 do
    push(colors, {
      x = NOM.left+x, y = NOM.top+y,
      w = col_w, h = col_h,

      border_size = (i == selected) and 2 or 1,
      border_color = bc,

      background = (i == 0) and 16 or i,
    })

    x += col_w-1

    if x > palette_width-spacing*2-col_w then
      x = spacing
      y += col_h-1
    end
  end

  return colors
end

function build_palette_numbers()
  local numbers = {}

  local line_height = 10

  local selected =  1

  for i=1,8 do
    push(numbers, {
           x = NOM.left+spacing, y = NOM.top+spacing+(i-1)*line_height,
           w = NOM.width-2*spacing, h = line_height,

           background = (selected == i) and 3 or 0,
           border_color = (selected == i) and 1 or 0,
           border_size = 1,

           radius = 2,

           content = "#"..tostring(i)
    })
  end

  return numbers
end

local nom = NOM:new({
  x = NOM.left, y = NOM.top,
  w = NOM.width, h = NOM.height,
  background = 14,

  -- Palette
  {
    x = NOM.left+spacing, y = NOM.top+spacing,
    w = palette_width-spacing, h = title_h,
    content = "COL",
  },
  {
    id = "palette",

    x = NOM.left+spacing, y = NOM.top+spacing+title_h,
    w = palette_width-2*spacing, h = palette_height,

    border_color = 3,
    border_size = 1,

    radius = 2,

    background = 7,

    unwrap(build_palette_colors())
  },

  -- Palette Selector
  {
    x = NOM.left+spacing, y = NOM.top+palette_height+2*spacing+title_h,
    w = palette_width-spacing, h = title_h,
    content = "PAL",
  },
  {
    id = "palette_selector",

    x = NOM.left+spacing, y = NOM.top+palette_height+2*spacing+2*title_h,
    w = palette_width-2*spacing, h = palette_selector_height,

    border_color = 3,
    border_size = 1,

    radius = 2,

    background = 7,

    unwrap(build_palette_numbers())
  },

  -- Drawing area
  {
    x = NOM.left+palette_width, y = NOM.top+spacing,
    w = NOM.width-palette_width-toolbar_width, h = NOM.height-2*spacing,

    border_color = 3,
    border_size = 1,

    radius = 2,

    background = 7,

    -- Canvas
    {
      id = "canvas",

      x = NOM.left+(NOM.width-sprite_w)/2, y = NOM.top+(NOM.height-sprite_h)/2,
      w = sprite_w+2, h = sprite_h+2,

      background = 8,
      border_size = 1,
      border_color = 1,

      draw = function(self)
        if self.dirty then
          Widget.draw(self)

          local x, y, w, h = self.x+1, self.y+1, self.w-2, self.h-2

          clip(x, y, w, h)

          local side = 8
          local colors = { 10, 8 }

          -- Draw a checkers pattern
          for iy=y,y+h,side do
            for ix=x,x+w,side do
              fill_rect(ix, iy, side, side, colors[math.floor(ix/side+iy/side) % 2 + 1])
            end
          end
        end
      end,
    }
  },

  -- Toolbar
  {
    x = NOM.right-toolbar_width, y = NOM.top+spacing,
    w = toolbar_width, h = NOM.height-2*spacing,

    {
      x = NOM.left+spacing, y = NOM.top+spacing,
      w = 16, h = 16,

      background = 8,
      border_size = 1,
      border_color = 4,

      radius = 2,

      content = "B"
    },
    {
      x = NOM.left+spacing, y = NOM.top+spacing+16+spacing,
      w = 16, h = 16,

      background = 8,
      border_size = 1,
      border_color = 4,

      radius = 2,

      content = "L"
    }
  },
})

function draw()
  nom:draw()
end

function update(dt)
  nom:update(dt)
end
