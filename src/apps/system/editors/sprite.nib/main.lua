require 'nibui.Neact'

local NOM = require 'nibui.NOM'
local Widget = require 'nibui.Widget'

local Sprite = Neact.Component:new()

local Palette = require 'Palette'
local PaletteSelector = require 'PaletteSelector'
local Canvas = require 'Canvas'

local spacing = 2

local title_h = 10

local palette_width = 27
local palette_height = 77
local palette_border_color = 16

local toolbar_width = 16+2*spacing

local palette_selector_height = 80+2*spacing

local function random_data(length)
  local data = {}

  for i=0,length-1 do
    data[i] = math.random(16)
  end

  return data
end

local function zero_data(length)
  local data = {}

  for i=0,length-1 do
    data[i] = 0
  end

  return data
end

function Sprite:new(props)
  return new(Sprite, {
               props = props,
               state = {
                 selected_color = 16,
                 selected_palette = 1,
                 sprite = { w = 16, h = 16, data = zero_data(15*16) },
                 zoom = 8,
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
      palette = state.selected_palette,

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
      {Canvas,
       color = state.selected_color,
       palette = state.selected_palette,
       sprite = state.sprite,
       scale = state.zoom}
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

nom.cursor["pencil"] = {
  x = 56, y = 80,
  w = 8, h = 8,
  hx = 0, hy = 8,
}

nom.cursor["hand"] = {
  x = 64, y = 80,
  w = 8, h = 8,
}

function draw()
  nom:draw()
end

function update(dt)
  nom:update(dt)
end
