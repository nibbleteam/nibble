local RevisionHistory = {}

local Bitmap = require 'Bitmap'

function RevisionHistory:new()
  return new(RevisionHistory, {
               past = {},
               future = {},
  })
end

function RevisionHistory:copy_region(spr, sx, sy, ex, ey)
  local rw = ex-sx+1
  local rh = ey-sy+1

  local bitmap = Bitmap:new(rw, rh, {})

  for y=sy,ey do
    for x=sx,ex do
      local p_src = y*spr.width+x
      local p_dst = (y-sy)*bitmap.width+(x-sx)

      bitmap.data[p_dst] = spr.data[p_src]
    end
  end

  return bitmap
end

function RevisionHistory:apply_region(spr, region, sx, sy)
  local ex, ey = sx+region.width, sy+region.height

  for y=sy,ey-1 do
    for x=sx,ex-1 do
      local p_src = (y-sy)*region.width+(x-sx)
      local p_dst = y*spr.width+x

      spr.data[p_dst] = region.data[p_src]
    end
  end
end

function RevisionHistory:snapshot(sprite, sx, sy, ex, ey)
  push(self.past, {
         x = sx, y = sy,

         bitmap = self:copy_region(sprite, sx, sy, ex, ey)
  })

  self.future = {}
end

function RevisionHistory:undo(sprite)
  local data = pop(self.past)

  if data then
    -- Do all the changes from a zeroed out sprite, except the last one
    sprite:clear()
    for _, data in ipairs(self.past) do
        self:apply_region(sprite, data.bitmap, data.x, data.y)
    end

    push(self.future, data)
  end
end

function RevisionHistory:redo(sprite)
  local data = pop(self.future)

  if data then
    self:apply_region(sprite, data.bitmap, data.x, data.y)

    push(self.past, data)
  end
end

return RevisionHistory
