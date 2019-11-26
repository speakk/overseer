local cpml = require('libs/cpml')
local commonComponents = require('components/common')

local PlayerInputSystem = ECS.System({commonComponents.PlayerInput})

local cameraSpeed = 500

function PlayerInputSystem:update(dt)
  -- velocity = commonComponents.Velocity(0, 0)
  vector = cpml.vec2(0, 0)
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
  vector = vector:normalize() * cameraSpeed
  for _, entity in ipairs(self.pool.objects) do
    if entity:has(commonComponents.Velocity) then
      entity:get(commonComponents.Velocity).vector = vector
    end
  end

end

return PlayerInputSystem
