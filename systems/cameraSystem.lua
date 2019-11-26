local commonComponents = require('components/common')

local camera = require('camera')

local CameraSystem = ECS.System({commonComponents.Position, commonComponents.Camera})

function CameraSystem:update(dt)
  for _, entity in ipairs(self.pool.objects) do
    local position = entity:get(commonComponents.Position)
    camera:setPosition(position.vector.x, position.vector.y);
  end
end

return CameraSystem
