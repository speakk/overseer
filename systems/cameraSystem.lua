local universe = require('models.universe')
local camera = require('models.camera')

local CameraSystem = ECS.System('camera')

function CameraSystem:init() --luacheck: ignore
  local cellSize = universe.getCellSize()
  local size = universe.getSize()
  camera:setWorld(cellSize, cellSize, size.x * cellSize, size.y * cellSize)
end

function CameraSystem:resize(w, h) --luacheck: ignore
  camera:setWindow(0, 0, w, h)
end

return CameraSystem
