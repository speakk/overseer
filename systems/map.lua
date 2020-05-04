--local entityFinder = require('models.entityFinder')
local Gamestate = require("libs.hump.gamestate")
local positionUtils = require('utils.position')
local inspect = require('libs.inspect') --luacheck: ignore
local Vector = require('libs.brinevector') --luacheck: ignore

local MapSystem = ECS.System({
  collision = { "collision", "position", "active" },
  onMap = { "onMap", "position" },
  onMapItem = {"onMap", "position", "selector" }
}
)

local function onCollisionEntityAdded(_, entity) --luacheck: ignore
  print("onCollisionEntityAdded", entity.position.vector)
  local position = positionUtils.pixelsToGridCoordinates(entity.position.vector)
  print("gridPos", position)
  Gamestate.current():changeMapAt(position.x, position.y, 1)
end

local function onCollisionEntityRemoved(_, entity)
    local position = positionUtils.pixelsToGridCoordinates(entity.position.vector)
    Gamestate.current():changeMapAt(position.x, position.y, 0)
end

return MapSystem
