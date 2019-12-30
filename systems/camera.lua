local universe = require('models.universe')
local camera = require('models.camera')

local settings = require('settings')

local CameraSystem = ECS.System()

function CameraSystem:init() --luacheck: ignore
  local cellSize = universe.getCellSize()
  local size = universe.getSize()
  camera:setWorld(cellSize, cellSize, size.x * cellSize, size.y * cellSize)
  camera:setWindow(0, 0, love.graphics.getWidth(), love.graphics.getHeight()-settings.actions_bar_height)
end

function CameraSystem:resize(w, h) --luacheck: ignore
  camera:setWindow(0, 0, w, h-settings.actions_bar_height)
end

return CameraSystem
