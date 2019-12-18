local utils = require('utils/utils')
local media = require('utils/media')
local commonComponents = require('components/common')
local Vector = require('libs/brinevector/brinevector')

local SpriteSystem = ECS.System({commonComponents.Sprite, commonComponents.Position})

function SpriteSystem:init()
  self.tilesetBatch = love.graphics.newSpriteBatch(media.sprites, 500)
end

function SpriteSystem:draw()

end

function SpriteSystem:generateSpriteBatch(l, t, w, h)
  self.tilesetBatch:clear()
  for _, entity in ipairs(self.pool.objects) do
    self:drawEntity(l, t, w, h, entity)
  end

  return self.tilesetBatch
end


function SpriteSystem:drawEntity(l, t, w, h, entity)
  local positionVector = entity:get(commonComponents.Position).vector
  --local draw = entity:get(commonComponents.Draw)
  local sizeVector = Vector(32, 32)
  if utils.withinBounds(positionVector.x,
    positionVector.y,
    positionVector.x + sizeVector.x,
    positionVector.y + sizeVector.y,
    l, t, l+w, t+h, sizeVector.x) then
    -- local color = draw.color
    -- local size = draw.size


    -- if entity:has(commonComponents.Job) then
    --   if entity:has(commonComponents.BluePrintJob) then
    --     local jobComponent = entity:get(commonComponents.Job)
    --     if jobComponent.finished then
    --       color[4] = 1.0
    --     else
    --       color[4] = 0.5
    --       love.graphics.setColor(1, 1, 1, 1)
    --       local progress = entity:get(commonComponents.BluePrintJob).buildProgress
    --       love.graphics.print(" " .. string.format("%d", progress) .. "%", positionVector.x, positionVector.y)
    --     end
    --   end
    -- end

    local spriteComponent = entity:get(commonComponents.Sprite)
    self.tilesetBatch:addLayer(media.getSpriteIndex(spriteComponent.selector), positionVector.x, positionVector.y, 0, 2, 2)

    -- love.graphics.setColor(color[1], color[2], color[3], color[4])
    -- love.graphics.rectangle("fill",
    -- positionVector.x,
    -- positionVector.y,
    -- size.x, size.y)

    -- if entity:has(commonComponents.Amount) then
    --   love.graphics.setColor(1, 1, 1)
    --   love.graphics.print(" " .. tostring(entity:get(commonComponents.Amount).amount),
    --   positionVector.x+10, positionVector.y+10)
    -- end

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

return SpriteSystem

