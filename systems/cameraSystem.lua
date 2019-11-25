local camera = require('camera')

-- Create a System class as lovetoys.System subclass.
local CameraSystem = class("CameraSystem", System)

-- Define this System's requirements.
function CameraSystem:requires()
  return {"position", "camera"}
end

function CameraSystem:update(dt)
  for _, entity in pairs(self.targets) do
    local position = entity:get("position")
    camera:setPosition(position.x, position.y);
  end
end

return CameraSystem
