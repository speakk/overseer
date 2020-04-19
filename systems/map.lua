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


return MapSystem
