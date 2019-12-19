local components = require('libs/concord').components
local universe = require('model/universe')

local MapSystem = ECS.System("map", {components.collision, "collision"})

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
