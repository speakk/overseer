local cpml = require('libs/cpml')
local commonComponents = require('components/common')
local camera = require('camera')

-- Create a draw System.
local DrawSystem = ECS.System({commonComponents.Position, commonComponents.Draw}, { commonComponents.Camera, "cameras" })

function DrawSystem:init(mapSystem)
  self.mapSystem = mapSystem
end

function DrawSystem:draw()
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
  camera:set()
  for _, entity in ipairs(self.pool.objects) do
    local color = entity:get(commonComponents.Draw).color
    love.graphics.setColor(color[1]*0.3, color[2]*0.3, color[3]*0.3)
    --local gridCornerPos = self.mapSystem:pixelsToGridCoordinates(entity:get(commonComponents.Position).vector)
    local gridCornerPos = self.mapSystem:snapPixelToGrid(entity:get(commonComponents.Position).vector)
    love.graphics.rectangle("fill", gridCornerPos.x, gridCornerPos.y, self.mapSystem:getCellSize(), self.mapSystem:getCellSize())
    love.graphics.setColor(color[1], color[2], color[3])
    love.graphics.rectangle("fill", entity:get(commonComponents.Position).vector.x, entity:get(commonComponents.Position).vector.y, 10, 10)

    if (entity:has(commonComponents.Path)) then
      local pathComponent = entity:get(commonComponents.Path)
      if pathComponent.path then
        local vertices = {}
        for node, count in pathComponent.path:nodes() do
          local pixelPosition = self.mapSystem:gridPositionToPixels(cpml.vec2(node:getX(), node:getY()), 'center', 2)
          table.insert(vertices, pixelPosition.x)
          table.insert(vertices, pixelPosition.y)
          --print(('Step: %d - x: %d - y: %d'):format(count, node:getX(), node:getY()))
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.line(vertices)
      end
    end


  end
  camera:unset()
end

return DrawSystem
