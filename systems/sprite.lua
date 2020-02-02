local inspect = require('libs.inspect')
local utils = require('utils.utils')
local universe = require('models.universe')
local camera = require('models.camera')
local media = require('utils.media')
local Vector = require('libs.brinevector')
local entityManager = require('models.entityManager')

local SpriteSystem = ECS.System({ECS.c.sprite, ECS.c.position})

function SpriteSystem:init()
  self.tilesetBatch = love.graphics.newSpriteBatch(media.sprites, 500)
end

function SpriteSystem:customDraw(l, t, w, h)
  self.tilesetBatch:clear()
  for _, entity in ipairs(self.pool) do
    self:drawEntity(l, t, w, h, entity)
  end

  love.graphics.draw(self.tilesetBatch)
end


function SpriteSystem:drawEntity(l, t, w, h, entity)
  if not entity:has(ECS.c.position) then return end
  local positionVector = entity:get(ECS.c.position).vector
  --local draw = entity:get(ECS.c.draw)
  local sizeVector = Vector(32, 32)
  if utils.withinBounds(positionVector.x,
    positionVector.y,
    positionVector.x + sizeVector.x,
    positionVector.y + sizeVector.y,
    l, t, l+w, t+h, sizeVector.x) then
    -- local color = draw.color
    -- local size = draw.size


    -- if entity:has(ECS.c.job) then
    --   if entity:has(ECS.c.bluePrintJob) then
    --     local jobComponent = entity:get(ECS.c.job)
    --     if jobComponent.finished then
    --       color[4] = 1.0
    --     else
    --       color[4] = 0.5
    --       love.graphics.setColor(1, 1, 1, 1)
    --       local progress = entity:get(ECS.c.bluePrintJob).buildProgress
    --       love.graphics.print(" " .. string.format("%d", progress) .. "%", positionVector.x, positionVector.y)
    --     end
    --   end
    -- end

    local spriteComponent = entity:get(ECS.c.sprite)
    local transparentComponent = entity:get(ECS.c.transparent)
    if transparentComponent then
      self.tilesetBatch:setColor(1, 1, 1, transparentComponent.amount)
    end
    self.tilesetBatch:addLayer(media.getSpriteIndex(spriteComponent.selector),
      positionVector.x, positionVector.y, 0, 2, 2)
    if transparentComponent then
      self.tilesetBatch:setColor(1, 1, 1, 1)
    end

    -- love.graphics.setColor(color[1], color[2], color[3], color[4])
    -- love.graphics.rectangle("fill",
    -- positionVector.x,
    -- positionVector.y,
    -- size.x, size.y)


  end
end

function SpriteSystem:generateGUIDraw()
  if DEBUG then
    local shader = love.graphics.getShader()
    for _, entity in ipairs(self.pool) do
      if not entity:has(ECS.c.position) then return end
      local positionVector = entity:get(ECS.c.position).vector

      love.graphics.setShader()

      if entity:has(ECS.c.amount) then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(" " .. tostring(entity:get(ECS.c.amount).amount),
        positionVector.x+10, positionVector.y+10)
      end

      if entity:has(ECS.c.inventory) then
        local inventory = entity:get(ECS.c.inventory).inventory
        local invIndex = 0
        local lineSpace = 10
        for _, itemId in ipairs(inventory) do
          local item = entityManager.get(itemId)
          local amount = item:get(ECS.c.amount).amount
          local selector = item:get(ECS.c.item).selector
          love.graphics.setColor(1, 1, 1, 1)
          love.graphics.print(selector .. ": " .. tostring(amount),
          positionVector.x+invIndex*lineSpace, positionVector.y+invIndex*lineSpace)
          invIndex = invIndex + 1
        end
      end

      if (entity:has(ECS.c.path)) then
        local pathComponent = entity:get(ECS.c.path)
        if pathComponent.path then
          local vertices = {}
          for node, count in pathComponent.path:nodes() do --luacheck: ignore
            local pixelPosition = universe.gridPositionToPixels(
            Vector(node:getX(), node:getY()), 'center', 2
            )
            love.graphics.circle('fill', pixelPosition.x, pixelPosition.y, 5)
            table.insert(vertices, pixelPosition.x)
            table.insert(vertices, pixelPosition.y)
          end
          if #vertices >= 4 then
            love.graphics.setColor(1, 1, 1)
            love.graphics.setLineWidth(2)
            love.graphics.line(vertices)
          end
        end
      end
    end

    love.graphics.setShader(shader)
  end
end

return SpriteSystem

