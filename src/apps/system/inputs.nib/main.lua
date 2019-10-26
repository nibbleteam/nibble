env.menu = {
  "Input Testing"
}

local W, H = 400, 240

local RECORD_AMOUNT = 80

local READY_MSG = "Inputs will be displayed above"

local BORDER_COLOR = 2
local GRAPH_COLOR = 11

local btns = {
  UP, DOWN, LEFT, RIGHT,
  RED, BLUE,
  WHITE, BLACK,
}

local btn_names = {
  [UP]    = "\1",
  [DOWN]  = "\3",
  [LEFT]  = "\2",
  [RIGHT] = "\4",
  [BLACK] = "\11",
  [WHITE] = "\10",
  [RED]   = "\9",
  [BLUE]  = "\8",
}

local btns_over_time = {}

function print_center(str, x, y)
  local w = measure(str)

  print(str, x-w/2, y-4)
end

function add_point(set, value)
  push(set, value)

  if #set > RECORD_AMOUNT then
    remove(set)
  end
end
  
function init()
  for _, btn in ipairs(btns) do
    btns_over_time[btn] = {}
  end
end

function draw_graph(btn, title, ox, oy)
  local px, py = nil, nil

  rect(ox-1, oy-1, RECORD_AMOUNT+2, 32, BORDER_COLOR)

  print(title, ox, oy)

  for x=1, RECORD_AMOUNT do
    local nx = ox+RECORD_AMOUNT-x
    local ny = oy+(btns_over_time[btn][x] or 0)

    if px and py then
      line(px, py, nx, ny, GRAPH_COLOR)
    end

    px, py = nx, ny
  end
end

function draw()
  clear(16)

  for ty=1,2 do
    for tx=1,4 do
      local b = (ty-1)*4+tx

      local off = (400-88*4)/2
      local x, y = (tx-1)*(RECORD_AMOUNT+8)+off, ty*40

      draw_graph(btns[b], btn_names[btns[b]], x, y)
    end
  end

  print_center(READY_MSG, W/2, H/2)
end

function update(dt)  
  for _, btn in ipairs(btns) do
    if button_down(btn) then
      print(tostring(btn), 0, 0)
      add_point(btns_over_time[btn], 29)
    elseif button_press(btn) then
      add_point(btns_over_time[btn], 20)
    elseif button_release(btn) then
      add_point(btns_over_time[btn], 10)
    elseif button_up(btn) then
      add_point(btns_over_time[btn], 00)
    end
  end
end