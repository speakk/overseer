local Vector = require('libs.brinevector')
local cpml = require('libs.cpml')

local camera = require('models.camera')

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
  --print("Vector victor", vector.x, vector.y)
  local x, y = camera:getPosition()
  local camX = x + vector.x*dt
  local camY = y + vector.y*dt
  camera:setPosition(camX, camY)
  self:getWorld():emit("cameraPositionChanged", camera:getPosition())
end

function PlayerInputSystem:wheelmoved(x, y) --luacheck: ignore
  local zoomSpeed = 0.3
  local maxZoom = 4
  local minZoom = 0.1
  local currentScale = camera:getScale()
  print(camera:getScale())
  currentScale = cpml.utils.clamp(currentScale + y * zoomSpeed, minZoom, maxZoom)
  camera:setScale(currentScale)
  self:getWorld():emit("cameraScaleChanged", camera:getScale())
end

return PlayerInputSystem
