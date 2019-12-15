local Vector = require('libs/brinevector/brinevector')
local cpml = require('libs/cpml')
local commonComponents = require('components/common')

local PlayerInputSystem = ECS.System({commonComponents.PlayerInput})

local cameraSpeed = 500

function PlayerInputSystem:init(overseerSystem, mapSystem, camera)
  self.overseerSystem = overseerSystem
  self.mapSystem = mapSystem
  --self.lightWorld = mapSystem:getLightWorld()
  self.camera = camera
end

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
  local x, y = self.camera:getPosition()
  local posX = x + vector.x*dt
  local posY = y + vector.y*dt
  self.camera:setPosition(posX, posY)
  --print("x y scale", posX, posY, self.camera:getScale())
  -- self.lightWorld:update(dt)
  -- self.lightWorld:setTranslation(posX, posY, self.camera:getScale())
  for _, entity in ipairs(self.pool.objects) do
    if entity:has(commonComponents.Velocity) then
      entity:get(commonComponents.Velocity).vector = vector
    end
  end

end

function PlayerInputSystem:mousepressed(x, y, button, istouch, presses) --luacheck: ignore
  -- ADD CAM TRANSFORM TO COORDINATES
  -- globalX, globalY = self.camera:toWorld(x, y)
  -- local position = self.mapSystem:pixelsToGridCoordinates(Vector(globalX, globalY))
  -- self.overseerSystem:enactClick(self.mapSystem:pixelsToGridCoordinates(Vector(globalX, globalY)))
  --self.bluePrintSystem:placeBlueprint(self.mapSystem:pixelsToGridCoordinates(Vector(globalX, globalY)))
end

function PlayerInputSystem:wheelmoved(x, y) --luacheck: ignore
  local zoomSpeed = 0.3
  local maxZoom = 4
  local minZoom = 0.1
  local currentScale = self.camera:getScale()
  print(self.camera:getScale())
  currentScale = cpml.utils.clamp(currentScale + y * zoomSpeed, minZoom, maxZoom)
  self.camera:setScale(currentScale)
  --self.lightWorld:setScale(currentScale)
end

return PlayerInputSystem
