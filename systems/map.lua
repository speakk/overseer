local universe = require('models.universe')
local entityManager = require('models.entityManager')
local inspect = require('libs.inspect') --luacheck: ignore
local Vector = require('libs.brinevector') --luacheck: ignore

local MapSystem = ECS.System({ECS.c.collision, "collision"},
  {ECS.c.onMap, ECS.c.position, "onMap"},
  {ECS.c.onMap, ECS.c.position, ECS.c.item, ECS.c.selector, "onMapItem"},
  {ECS.c.onMap, ECS.c.position, ECS.c.occluder, "occluder"}
  )

function MapSystem:init()
  self.collision.onEntityAdded = universe.onCollisionEntityAdded
  self.collision.onEntityRemoved = universe.onCollisionEntityRemoved
  self.occluder.onEntityAdded = universe.onOccluderEntityAdded
  self.occluder.onEntityRemoved = universe.onOccluderEntityRemoved
  self.onMap.onEntityAdded = universe.onOnMapEntityAdded
  self.onMap.onEntityRemoved = universe.onOnMapEntityRemoved
  self.onMapItem.onEntityAdded = universe.onOnMapItemAdded
  self.onMapItem.onEntityRemoved = universe.onOnMapItemRemoved
end

function MapSystem:update(dt) --luacheck: ignore
  universe.update(dt)
end

function MapSystem:customDraw(l, t, w, h) --luacheck: ignore
  local draw = universe.draw(l, t, w, h)
  --love.graphics.push()
  --local transform = love.math.newTransform()
  --love.graphics.replaceTransform(transform)
  --love.graphics.origin()
  love.graphics.draw(draw, 32, 32)
  --love.graphics.draw(draw, 100, 100)
  --love.graphics.draw(draw, -300, -600)
  --love.graphics.pop()
end

function recursiveDelete(self, entity)
  if entity:has(ECS.c.children) then
    for _, childId in ipairs(entity:get(ECS.c.children).children) do
      local child = entityManager.get(childId)
      recursiveDelete(self, child)
    end
  end
  self:getWorld():removeEntity(entity)
end

function MapSystem:cancelConstruction(entities)
  for _, entity in ipairs(entities) do
    -- TODO: Deal with proper removal of already constructed entities
    -- if entity:has(ECS.c.removeCallBack) then
    --   entity:get(ECS.c.removeCallBack).callBack()
    -- else
      --entityManager.entityRemoved
      recursiveDelete(self, entity)

      --self:getWorld():removeEntity(entity)
    --end
  end
end

return MapSystem
