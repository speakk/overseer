local camera = require('camera')

-- Create a draw System.
local DrawSystem = class("DrawSystem", System)

-- Define this System requirements.
function DrawSystem:requires()
  return {"position", "draw"}
end

function DrawSystem:draw()
  camera:set()
  for _, entity in pairs(self.targets) do
    local color = entity:get("draw").color
    love.graphics.setColor(color[1], color[2], color[3])
    love.graphics.rectangle("fill", entity:get("position").x, entity:get("position").y, 10, 10)
  end
  camera:unset()
end

return DrawSystem
