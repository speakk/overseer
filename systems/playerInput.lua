local Vector = require('libs.brinevector')
local cpml = require('libs.cpml')

local camera = require('models.camera')

local PlayerInputSystem = ECS.System()

local cameraSpeed = 800

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

function PlayerInputSystem:keypressed(pressedKey, scancode, isrepeat) --luacheck: ignore
  if pressedKey == 'f5' then
    self:getWorld():emit("saveGame")
  end

  if pressedKey == 'f9' then
    self:getWorld():emit("loadGame")
  end
end

return PlayerInputSystem
