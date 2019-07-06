function init()
   local x, y = math.random()*320, math.random()*240

   tri(
      x, y,
      160, 120,
      10, 120,
      4
   )

   fill_tri(
      x, y,
      160, 120,
      10, 120,
      6
   )

   put_pixel(x, y, 8)
   put_pixel(160, 120, 9)
   put_pixel(10, 120, 10)
end
