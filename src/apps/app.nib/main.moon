export draw, update

ball =
  x: 320/2,
  y: 240/2,

  vx: 8,
  vy: -8,

  r: 8,
  color: 9

draw = () ->
  clear 8

  fill_circ ball.x, ball.y, ball.r, ball.color

update = (dt) ->
  ball.x += ball.vx*dt
  ball.y += ball.vy*dt
