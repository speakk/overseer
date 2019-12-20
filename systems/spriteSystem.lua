local utils = require('utils/utils')
local media = require('utils/media')
local Vector = require('libs/brinevector/brinevector')

local SpriteSystem = ECS.System("sprite", {ECS.Components.sprite, ECS.Components.position})

function SpriteSystem:init()
  self.tilesetBatch = love.graphics.newSpriteBatch(media.sprites, 500)
end

function SpriteSystem:generateSpriteBatch(l, t, w, h)
  self.tilesetBatch:clear()
  for _, entity in ipairs(self.pool) do
    self:drawEntity(l, t, w, h, entity)
  end

  return self.tilesetBatch
end


function SpriteSystem:drawEntity(l, t, w, h, entity)
  local positionVector = entity:get(ECS.Components.position).vector
  --local draw = entity:get(ECS.Components.draw)
  local sizeVector = Vector(32, 32)
  if utils.withinBounds(positionVector.x,
    positionVector.y,
    positionVector.x + sizeVector.x,
    positionVector.y + sizeVector.y,
    l, t, l+w, t+h, sizeVector.x) then
    -- local color = draw.color
    -- local size = draw.size


    -- if entity:has(ECS.Components.job) then
    --   if entity:has(ECS.Components.bluePrintJob) then
    --     local jobComponent = entity:get(ECS.Components.job)
    --     if jobComponent.finished then
    --       color[4] = 1.0
    --     else
    --       color[4] = 0.5
    --       love.graphics.setColor(1, 1, 1, 1)
    --       local progress = entity:get(ECS.Components.bluePrintJob).buildProgress
    --       love.graphics.print(" " .. string.format("%d", progress) .. "%", positionVector.x, positionVector.y)
    --     end
    --   end
    -- end

    local spriteComponent = entity:get(ECS.Components.sprite)
    self.tilesetBatch:addLayer(media.getSpriteIndex(spriteComponent.selector),
      positionVector.x, positionVector.y, 0, 2, 2)

    -- love.graphics.setColor(color[1], color[2], color[3], color[4])
    -- love.graphics.rectangle("fill",
    -- positionVector.x,
    -- positionVector.y,
    -- size.x, size.y)

    -- if entity:has(ECS.Components.amount) then
    --   love.graphics.setColor(1, 1, 1)
    --   love.graphics.print(" " .. tostring(entity:get(ECS.Components.amount).amount),
    --   positionVector.x+10, positionVector.y+10)
    -- end

    if DEBUG then
      if (entity:has(ECS.Components.path)) then
        local pathComponent = entity:get(ECS.Components.path)
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

