local universe = require('models.universe')
local inspect = require('libs.inspect') --luacheck: ignore
local Vector = require('libs.brinevector') --luacheck: ignore

local MapSystem = ECS.System({ECS.c.collision, "collision"},
  {ECS.c.onMap, ECS.c.position, "onMap"},
  {ECS.c.onMap, ECS.c.position, ECS.c.item, "onMapItem"})

function MapSystem:init()
  self.collision.onEntityAdded = universe.onCollisionEntityAdded
  self.collision.onEntityRemoved = universe.onCollisionEntityRemoved
  self.onMap.onEntityAdded = universe.onOnMapEntityAdded
  self.onMap.onEntityRemoved = universe.onOnMapEntityRemoved
  self.onMapItem.onEntityAdded = universe.onOnMapItemAdded
  self.onMapItem.onEntityRemoved = universe.onOnMapItemRemoved
end

function MapSystem:update(dt) --luacheck: ignore
  universe.update(dt)
end

function MapSystem:generateSpriteBatch(l, t, w, h) --luacheck: ignore
  return universe.generateSpriteBatch(l, t, w, h)
end

function MapSystem:cancelConstruction(entities)
  for _, entity in ipairs(entities) do
    -- TODO: Deal with proper removal of already constructed entities
    -- if entity:has(ECS.c.removeCallBack) then
    --   entity:get(ECS.c.removeCallBack).callBack()
    -- else
      --entityManager.entityRemoved
      self:getWorld():removeEntity(entity)
    --end
  end
end

return MapSystem
