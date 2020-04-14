--local entityFinder = require('models.entityFinder')
local Gamestate = require("libs.hump.gamestate")
local positionUtils = require('utils.position')
local entityRegistry = require('models.entityRegistry')
local inspect = require('libs.inspect') --luacheck: ignore
local Vector = require('libs.brinevector') --luacheck: ignore

local MapSystem = ECS.System({
  collision = { "collision", "position", "active" },
  onMap = { "onMap", "position" },
  onMapItem = {"onMap", "position", "selector" }
}
)

function onCollisionEntityAdded(_, entity) --luacheck: ignore
  print("onCollisionEntityAdded", entity.position.vector)
  local position = positionUtils.pixelsToGridCoordinates(entity.position.vector)
  print("gridPos", position)
  Gamestate.current():changeMapAt(position.x, position.y, 1)
end

function onCollisionEntityRemoved(_, entity)
    local position = positionUtils.pixelsToGridCoordinates(entity.position.vector)
    Gamestate.current():changeMapAt(position.x, position.y, 0)
end

function MapSystem:init()
  -- self.collision.onEntityAdded = onCollisionEntityAdded
  -- self.collision.onEntityRemoved = onCollisionEntityRemoved
  -- self.onMap.onEntityAdded = entityFinder.onOnMapEntityAdded
  -- self.onMap.onEntityRemoved = entityFinder.onOnMapEntityRemoved
  -- self.onMapItem.onEntityAdded = entityFinder.onOnMapItemAdded
  -- self.onMapItem.onEntityRemoved = entityFinder.onOnMapItemRemoved
end

local function recursiveDelete(self, entity)
  if entity.children then
    for _, childId in ipairs(entity.children.children) do
      local child = entityRegistry.get(childId)
      recursiveDelete(self, child)
    end
  end

  if entity.inventory then
    local inventory = entity.inventory

    for _, itemId in ipairs(inventory.inventory) do
      print("itemId", itemId)
      local item = entityRegistry.get(itemId)
      print("item", item)
      item:give("onMap")
      -- TODO: If no space then randomize nearby position
      --local itemPosition = currentGridPosition
      item:give("position", entity.position.vector.copy)
    end
  end

  self:getWorld():removeEntity(entity)
end

function MapSystem:cancelConstruction(entities)
  for _, entity in ipairs(entities) do
      if entity.construction then
        if not entity.job or not entity.job.jobType == "destruct" then
          -- TODO: Using immediateDestroy here, but really should do destructFinished
          entity:give("job", "destruct", "immediateDestroy")
        end
      else
        recursiveDelete(self, entity)
      end
  end
end

function MapSystem:immediateDestroy(entity)
  recursiveDelete(self, entity)
end

local destructSpeedModifier = 5
function MapSystem:destructProgress(constructionComponent, amount) -- luacheck: ignore
  constructionComponent.durability = constructionComponent.durability - amount * destructSpeedModifier
  print("durability now", constructionComponent.durability)
end

return MapSystem
