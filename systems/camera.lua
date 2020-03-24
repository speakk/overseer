local camera = require('models.camera')
local Gamestate = require("libs.hump.gamestate")

local settings = require('settings')

local CameraSystem = ECS.System()

function CameraSystem:init() --luacheck: ignore
  local mapConfig = Gamestate.current().mapConfig
  local cellSize = mapConfig.cellSize
  camera:setWorld(cellSize, cellSize, mapConfig.width * cellSize, mapConfig.height * cellSize)
  camera:setWindow(0, 0, love.graphics.getWidth(), love.graphics.getHeight()-settings.actions_bar_height)
end

function CameraSystem:resize(w, h) --luacheck: ignore
  camera:setWindow(0, 0, w, h-settings.actions_bar_height)
end

function CameraSystem:debugModeChanged(newMode) -- luacheck: ignore
  local entityDebugWidth = 0
  if newMode then
    entityDebugWidth = settings.entity_debugger_width
  end

  camera:setWindow(0, 0,
  love.graphics.getWidth()-entityDebugWidth, love.graphics.getHeight()-settings.actions_bar_height)
end

return CameraSystem
