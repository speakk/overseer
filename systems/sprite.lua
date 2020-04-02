local Vector = require('libs.brinevector')
local Gamestate = require('libs.hump.gamestate')
local lume = require('libs.lume')

local utils = require('utils.utils')
local media = require('utils.media')

local positionUtils = require('utils.position')
local entityRegistry = require('models.entityRegistry')

local SpriteSystem = ECS.System( { pool = { "sprite", "position" } })

local sortPool = {}

function SpriteSystem:init()
  self.tilesetBatch = love.graphics.newSpriteBatch(media.atlas, 500)

  self.pool.onEntityAdded = function(pool, entity)
    table.insert(sortPool, entity)
  end

  self.pool.onEntityRemoved = function(pool, entity)
    lume.remove(sortPool, entity)
  end
end

function SpriteSystem:customDraw(l, t, w, h)
  self.tilesetBatch:clear()
  local zSorted = table.insertion_sort(sortPool, function(a, b)
    return a.position.vector.y < b.position.vector.y
  end)
  for _, entity in ipairs(zSorted) do
    self:drawEntity(l, t, w, h, entity)
  end

  love.graphics.draw(self.tilesetBatch)
end


function SpriteSystem:drawEntity(l, t, w, h, entity)
  if not entity.position then return end
  local positionVector = entity.position.vector
  --local draw = entity.draw
  local sizeVector = Vector(32, 32)
  if utils.withinBounds(positionVector.x,
    positionVector.y,
    positionVector.x + sizeVector.x,
    positionVector.y + sizeVector.y,
    l, t, l+w, t+h, sizeVector.x) then

    local spriteComponent = entity.sprite
    local transparentComponent = entity.transparent
    if transparentComponent then
      self.tilesetBatch:setColor(1, 1, 1, transparentComponent.amount)
    end

    local sprite = media.getSprite(spriteComponent.selector)
    local quad = sprite.quad
    local _, _, quadW, quadH = quad:getViewport()
    local scaleX = 2
    local scaleY = 2

    local originX = sprite.originX * quadW
    local originY = sprite.originX * quadH

    if entity.animation then
      if entity.animation.flipped then
        scaleX = -2
      end
    end

    local cellSize = Gamestate.current().mapConfig.cellSize
    local finalX = positionVector.x + cellSize / 2
    local finalY = positionVector.y + cellSize / 2

    self.tilesetBatch:add(quad,
      finalX, finalY, 0, scaleX, scaleY, originX, originY)
    if transparentComponent then
      self.tilesetBatch:setColor(1, 1, 1, 1)
    end
  end
end

function SpriteSystem:generateGUIDraw()
  if DEBUG then
    local shader = love.graphics.getShader()
    for _, entity in ipairs(self.pool) do
      if not entity.position then return end
      local positionVector = entity.position.vector

      love.graphics.setShader()

      if entity.amount then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(" " .. tostring(entity.amount.amount),
        positionVector.x+10, positionVector.y+10)
      end

      if entity.inventory then
        local inventory = entity.inventory.inventory
        local invIndex = 0
        local lineSpace = 10
        for _, itemId in ipairs(inventory) do
          local item = entityRegistry.get(itemId)
          local amount = item.amount.amount
          local selector = item.selector.selector
          love.graphics.setColor(1, 1, 1, 1)
          love.graphics.print(selector .. ": " .. tostring(amount),
          positionVector.x+invIndex*lineSpace, positionVector.y+invIndex*lineSpace)
          invIndex = invIndex + 1
        end
      end

      if (entity.path) then
        local pathComponent = entity.path
        if pathComponent.path then
          local vertices = {}
          for node, count in pathComponent.path:nodes() do --luacheck: ignore
            local pixelPosition = positionUtils.gridPositionToPixels(
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

