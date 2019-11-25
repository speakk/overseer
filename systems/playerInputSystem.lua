local cpml = require('libs/cpml')
local commonComponents = require('components/common')

local PlayerInputSystem = class("PlayerInputSystem", System)

local cameraSpeed = 500

function PlayerInputSystem:requires()
  return {"playerInput"}
end

function PlayerInputSystem:update(dt)
  -- velocity = commonComponents.Velocity(0, 0)
  velocity = commonComponents.Velocity(cpml.vec2(0, 0))
  if love.keyboard.isDown("w") then
    velocity.vector.y = -1
  end
  if love.keyboard.isDown("s") then
    velocity.vector.y = 1
  end
  if love.keyboard.isDown("a") then
    velocity.vector.x = -1
  end
  if love.keyboard.isDown("d") then
    velocity.vector.x = 1
  end
  velocity.vector = velocity.vector:normalize() * cameraSpeed
  for _, entity in pairs(self.targets) do
    if entity:has("velocity") then
      entity:set(velocity)
    end
  end

end

return PlayerInputSystem
