local Vector = require('libs/brinevector/brinevector')
local commonComponents = require('components/common')
local utils = require('utils/utils')

-- Create a draw System.
local DrawSystem = ECS.System({commonComponents.Position, commonComponents.Draw})

function DrawSystem:init(mapSystem, camera)
  self.mapSystem = mapSystem
  self.camera = camera
end

function DrawSystem:draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
  self.camera:draw(function(l,t,w,h)
    for _, entity in ipairs(self.pool.objects) do
      local positionVector = entity:get(commonComponents.Position).vector
      local draw = entity:get(commonComponents.Draw)
      local sizeVector = draw.size
      if utils.withinBounds(positionVector.x,
        positionVector.y,
        positionVector.x + sizeVector.x,
        positionVector.y + sizeVector.y,
        l, t, l+w, t+h, sizeVector.x)
        then
          local color = draw.color
          --local gridCornerPos = self.mapSystem:snapPixelToGrid(positionVector)
          local size = draw.size
          --if entity:has(commonComponents.Item) and not entity:has(commonComponents.BluePrintJob) then
          --  size = 16
          --end
          --if entity:has(commonComponents.BluePrintJob) then
          --  if entity:get(commonComponents.Job).finished then
          --    color = { 0, 0, 1 }
          --  end
          --end
          --love.graphics.setColor(color[1]*0.3, color[2]*0.3, color[3]*0.3)
          -- love.graphics.rectangle("fill",
          --   gridCornerPos.x,
          --   gridCornerPos.y,
          --   size,
          --   size
          -- )
          love.graphics.setColor(color[1], color[2], color[3], color[4])
          love.graphics.rectangle("fill",
          positionVector.x,
          positionVector.y,
          size.x, size.y)

          if entity:has(commonComponents.Job) then
            if entity:has(commonComponents.BluePrintJob) then
              love.graphics.setColor(1, 1, 1)
              love.graphics.print("Unfinished", positionVector.x, positionVector.y)
            end
            color[4] = 0.5
          else
            if entity:has(commonComponents.BluePrintJob) then
              love.graphics.setColor(1, 1, 1)
              love.graphics.print("Finished", positionVector.x, positionVector.y)
            end
            color[4] = 1.0
          end
          if entity:has(commonComponents.Amount) then
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(" " .. tostring(entity:get(commonComponents.Amount).amount),
              positionVector.x+10, positionVector.y+10)
          end

          if DEBUG then
            if (entity:has(commonComponents.Path)) then
              local pathComponent = entity:get(commonComponents.Path)
              if pathComponent.path then
                local vertices = {}
                for node, count in pathComponent.path:nodes() do --luacheck: ignore
                  local pixelPosition = self.mapSystem:gridPositionToPixels(
                    Vector(node:getX(), node:getY()), 'center', 2
                  )
                  table.insert(vertices, pixelPosition.x)
                  table.insert(vertices, pixelPosition.y)
                end
                love.graphics.setColor(1, 1, 1)
                love.graphics.line(vertices)
              end
            end
          end
        end


      end
    end)
  end

  return DrawSystem
