local universe = require('models.universe')
local inspect = require('libs.inspect')

local MapSystem = ECS.System("map", {ECS.Components.collision, "collision"})

function MapSystem:init()
  self.collision.onEntityAdded = universe.onCollisionEntityAdded
  self.collision.onEntityRemoved = universe.onCollisionEntityRemoved
end

function MapSystem:update(dt) --luacheck: ignore
  universe.update(dt)
end

function MapSystem:generateSpriteBatch(l, t, w, h) --luacheck: ignore
  return universe.generateSpriteBatch(l, t, w, h)
end

return MapSystem
