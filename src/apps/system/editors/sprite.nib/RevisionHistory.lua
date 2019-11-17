local RevisionHistory = {}

local Bitmap = require 'Bitmap'

function RevisionHistory:new(w, h, bitmap)
  return new(RevisionHistory, {
               past = {},
               future = {},

               internal = RevisionHistory:copy_region(bitmap, 0, 0, bitmap.width-1, bitmap.height-1)
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
  local redo = self:copy_region(sprite, sx, sy, ex, ey)
  local undo = self:copy_region(self.internal, sx, sy, ex, ey)

  push(self.past, {
         x = sx, y = sy,

         after = redo,
         before = undo,
  })

  self:apply_region(self.internal, redo, sx, sy)

  self.future = {}
end

function RevisionHistory:undo(sprite)
  local revision = pop(self.past)

  if revision then
    self:apply_region(sprite, revision.before, revision.x, revision.y)
    self:apply_region(self.internal, revision.before, revision.x, revision.y)

    push(self.future, revision)
  end
end

function RevisionHistory:redo(sprite)
  local revision = pop(self.future)

  if revision then
    self:apply_region(sprite, revision.after, revision.x, revision.y)
    self:apply_region(self.internal, revision.after, revision.x, revision.y)

    push(self.past, revision)
  end
end

return RevisionHistory
