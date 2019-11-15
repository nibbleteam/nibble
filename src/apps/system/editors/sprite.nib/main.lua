require 'nibui.Neact'

local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'

local Sprite = Neact.Component:new()

local Palette = require 'Palette'
local PaletteSelector = require 'PaletteSelector'

local spacing = 2

local title_h = 10

local palette_width = 27
local palette_height = 77
local palette_border_color = 16

local toolbar_width = 16+2*spacing

local palette_selector_height = 80+2*spacing

local sprite_w, sprite_h = 128, 128

function Sprite:new(props)
  return new(Sprite, {
               props = props,
               state = {
                 selected_color = 1,
                 selected_palette = 1,
               }
  })
end

function Sprite:render(state, props)
  return {
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
      Palette,

      x = NOM.left+spacing, y = NOM.top+spacing+title_h,
      w = palette_width-2*spacing, h = palette_height,

      border_color = palette_border_color,
      width = palette_width,
      height = palette_height,
      spacing = spacing,

      selected = state.selected_color,

      onchange = function(color)
        self:set_state({
            selected_color = color
        })
      end
    },

    -- Palette Selector
    {
      x = NOM.left+spacing, y = NOM.top+palette_height+2*spacing+title_h,
      w = palette_width-spacing, h = title_h,
      content = "PAL",
    },
    {
      PaletteSelector,
     
      x = NOM.left+spacing, y = NOM.top+palette_height+2*spacing+2*title_h,
      w = palette_width-2*spacing, h = palette_selector_height,

      spacing = spacing,

      selected = state.selected_palette,

      onchange = function(palette)
        self:set_state({
            selected_palette = palette
        })
      end
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
  }
end

local sprite_editor = Sprite:new({})
local nom = sprite_editor:nom():use('cursor')

function draw()
  nom:draw()
end

function update(dt)
  nom:update(dt)
end
