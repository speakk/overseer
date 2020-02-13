local inspect = require('libs.inspect')
local lume = require('libs.lume')
local utils = require('utils.utils')
local universe = require('models.universe')
local camera = require('models.camera')
local media = require('utils.media')
local Vector = require('libs.brinevector')
local entityManager = require('models.entityManager')

local SpriteSystem = ECS.System({ECS.c.sprite, ECS.c.position})

local cellSize = universe.getCellSize()

function SpriteSystem:init()
  self.tilesetBatch = love.graphics.newSpriteBatch(media.atlas, 500)
end

function SpriteSystem:customDraw(l, t, w, h)
  self.tilesetBatch:clear()
  -- TODO: OPTIMIZE THIS SUCKER
  local zSorted = lume.sort(self.pool, function(a, b) return a:get(ECS.c.position).vector.y < b:get(ECS.c.position).vector.y end)
  for _, entity in ipairs(zSorted) do
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

    local quad = media.getSpriteQuad(spriteComponent.selector)
    local _, _, w, h = quad:getViewport()
    local finalY = positionVector.y + (cellSize - h*2)
    self.tilesetBatch:add(quad,
      positionVector.x, finalY, 0, 2, 2)
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
          local selector = item:get(ECS.c.selector).selector
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

