local W, H = 320, 240

local SPEED = 16

local player = {
  x = W/2, y = H/2
}

local directions = {
  [DOWN] = { 0, 16 },
  [UP]   = { 0, -16 },
  [LEFT] = { -16, 0 },
  [RIGHT] = { 16, 0 }
}

function draw()
  clear(1)

  fill_circ(player.x, player.y, 6, 8)
end

function update(dt)
  local buttons = { UP, DOWN, LEFT, RIGHT }

  for _, btn in ipairs(buttons) do
    if button_down(btn) then
      player.x += dt*directions[btn][1]
      player.y += dt*directions[btn][2]
    end
  end
end



