local Vector = require('libs/brinevector/brinevector')
local cpml = require('libs/cpml')

local camera = require('models/camera')

local PlayerInputSystem = ECS.System("playerInput")

local cameraSpeed = 500

function PlayerInputSystem:update(dt)
  local vector = Vector(0, 0)
  if love.keyboard.isDown("w") then
    vector.y = -1
  end
  if love.keyboard.isDown("s") then
    vector.y = 1
  end
  if love.keyboard.isDown("a") then
    vector.x = -1
  end
  if love.keyboard.isDown("d") then
    vector.x = 1
  end
  vector = vector.normalized * cameraSpeed
  local x, y = camera:getPosition()
  local posX = x + vector.x*dt
  local posY = y + vector.y*dt
  camera:setPosition(math.floor(posX), math.floor(posY))
end

function PlayerInputSystem:wheelmoved(x, y) --luacheck: ignore
  local zoomSpeed = 0.3
  local maxZoom = 4
  local minZoom = 0.1
  local currentScale = self.camera:getScale()
  print(self.camera:getScale())
  currentScale = cpml.utils.clamp(currentScale + y * zoomSpeed, minZoom, maxZoom)
  self.camera:setScale(currentScale)
end

return PlayerInputSystem
