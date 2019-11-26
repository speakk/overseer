local commonComponents = require('components/common')
local camera = require('camera')

-- Create a draw System.
local DrawSystem = ECS.System({commonComponents.Position, commonComponents.Draw}, { commonComponents.Camera, "cameras" })

function DrawSystem:draw()
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
  camera:set()
  for _, entity in ipairs(self.pool.objects) do
    local color = entity:get(commonComponents.Draw).color
    love.graphics.setColor(color[1], color[2], color[3])
    love.graphics.rectangle("fill", entity:get(commonComponents.Position).vector.x, entity:get(commonComponents.Position).vector.y, 10, 10)
  end
  camera:unset()
end

return DrawSystem
