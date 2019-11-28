local Vector = require('libs/brinevector/brinevector')
local cpml = require('libs/cpml')
local commonComponents = require('components/common')

local PlayerInputSystem = ECS.System({commonComponents.PlayerInput})

local cameraSpeed = 500

function PlayerInputSystem:init(bluePrintSystem, mapSystem, camera)
  self.bluePrintSystem = bluePrintSystem
  self.mapSystem = mapSystem
  self.camera = camera
end

function PlayerInputSystem:update(dt)
  -- velocity = commonComponents.Velocity(0, 0)
  vector = Vector(0, 0)
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
  x, y = self.camera:getPosition()
  self.camera:setPosition(x + vector.x*dt, y + vector.y*dt)
  for _, entity in ipairs(self.pool.objects) do
    if entity:has(commonComponents.Velocity) then
      entity:get(commonComponents.Velocity).vector = vector
    end
  end

end

function PlayerInputSystem:mousepressed(x, y, button, istouch, presses)
  -- ADD CAM TRANSFORM TO COORDINATES
  globalX, globalY = self.camera:toWorld(x, y)
  local position = self.mapSystem:pixelsToGridCoordinates(Vector(globalX, globalY))
  self.bluePrintSystem:placeBlueprint(self.mapSystem:pixelsToGridCoordinates(Vector(globalX, globalY)))
end

function PlayerInputSystem:wheelmoved(x, y)
  local zoomSpeed = 0.3
  local maxZoom = 4
  local minZoom = 0.1
  local currentScale = self.camera:getScale()
  print(self.camera:getScale())
  currentScale = cpml.utils.clamp(currentScale + y * zoomSpeed, minZoom, maxZoom)
  self.camera:setScale(currentScale)
end

return PlayerInputSystem
