local camera = require('models.camera')
local universe = require('models.universe')
local media = require('utils.media')
local Vector = require('libs.brinevector')
local lume = require('libs.lume')

local size = universe.getSize()
local width = size.x
local height = size.y
local cellSize = universe.getCellSize()
local map = universe.getMap()
local mapColors = universe.getMapColors()

local randomWalkX = {}
local randomWalkY = {}
for i=1,width do
  table.insert(randomWalkX, i)
end
for i=1,height do
  table.insert(randomWalkY, i)
end

randomWalkX = lume.shuffle(randomWalkX)
randomWalkY = lume.shuffle(randomWalkY)

-- Create a draw System.
local DrawSystem = ECS.System({ pool = {"position", "sprite"}})

local tilesetBatch = love.graphics.newSpriteBatch(media.atlas, 500)
local cachedCanvas

function DrawSystem:init()
  self.drawFunctions = {}
  self.guiDrawGenerators = {}
  self.guiCameraDrawGenerators = {}
end

function DrawSystem:registerDrawFunction(callee, callBack)
  table.insert(self.drawFunctions, { callee = callee, callBack = callBack})
end

function DrawSystem:registerGUIDrawGenerator(callee, callBack, inCamera)
  if inCamera then
    table.insert(self.guiCameraDrawGenerators, { callee = callee, callBack = callBack})
  else
    table.insert(self.guiDrawGenerators, { callee = callee, callBack = callBack})
  end
end

function DrawSystem:draw()
  love.graphics.setColor(1, 1, 1, 1)
  camera:draw(function(l,t,w,h)
    --l,t,w,h = 0, 0, 1000, 1000
    -- TODO: Do not use getWorld getSystem here, figure out a better way
    self:getWorld():getSystem(ECS.Systems.light):renderLights(l, t, w, h, function()
      love.graphics.draw(drawUniverse(l,t,w,h), 32, 32)
      for _, drawFunction in ipairs(self.drawFunctions) do
        --local batch = spriteBatchGenerator.callBack(spriteBatchGenerator.callee, l, t, w, h)
        --love.graphics.draw(batch)
        drawFunction.callBack(drawFunction.callee, l, t, w, h)
      end
    end)

    for _, guiDrawGenerator in ipairs(self.guiCameraDrawGenerators) do
      guiDrawGenerator.callBack(guiDrawGenerator.callee, l, t, w, h)
    end
    -- local mapBatch = self.mapSystem:generateSpriteBatch(l, t, w, h)
    -- love.graphics.draw(mapBatch)
    -- local spriteBatch = self.spriteSystem:generateSpriteBatch(l, t, w, h)
    -- love.graphics.draw(spriteBatch)
  end)

  for _, guiDrawGenerator in ipairs(self.guiDrawGenerators) do
    guiDrawGenerator.callBack(guiDrawGenerator.callee)
  end

  love.graphics.setColor(1, 1, 0)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10, 0, 1.3, 1.3)
  --love.graphics.print("Amount of jobs: "..tostring(#self.jobSystem.pool), 10, 40, 0, 1.3, 1.3)
end

function drawUniverse(l, t, w, h)
  if cachedCanvas then
    return cachedCanvas
  else
    tilesetBatch:clear()
    love.graphics.push()
    love.graphics.origin()
    local scissorX, scissorY, scissorW, scissorH = love.graphics.getScissor()
    love.graphics.setScissor()

    for randomY = 1,height do
      local rowNum = randomWalkY[randomY]
      local row = map[rowNum]
      for randomX = 1,width do
        local cellNum = randomWalkX[randomX]
        local cellValue = row[cellNum]
        local color = mapColors[rowNum][cellNum]
        local spriteSelector = "tiles.dirt01"
        if color.grass == 1 then
          spriteSelector = "tiles." .. lume.randomchoice({"grass01", "grass02"})
        end
        
        if color.water == 1 then
          spriteSelector = "tiles." .. lume.randomchoice({"water01", "water02"})
        end

        local randColor = 0.94+color.a*0.06
        tilesetBatch:setColor(randColor, randColor, randColor, 1)
        local quad = media.getSpriteQuad(spriteSelector)
        local _, _, quadW, quadH = quad:getViewport()
        local offsetX = (cellSize - quadW)
        local offsetY = (cellSize - quadH)
        tilesetBatch:add(quad, cellNum*cellSize-cellSize + offsetX, rowNum*cellSize-cellSize + offsetY, 0, 2, 2)
        if color.foliage == 1 and universe.isPositionWalkable(Vector(randomX, randomY)) then
          local grassSelector = "vegetation." .. lume.randomchoice({"grass01", "grass02", "grass03"})
          tilesetBatch:add(media.getSpriteQuad(grassSelector), cellNum*cellSize-cellSize, rowNum*cellSize-cellSize, 0, 2, 2)
        end
      end
    end

    local canvas = love.graphics.newCanvas(width*cellSize, height*cellSize)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.draw(tilesetBatch)
    love.graphics.setCanvas()
    cachedCanvas = canvas
    love.graphics.pop()
    love.graphics.setScissor(scissorX, scissorY, scissorW, scissorH)
    return canvas
    --return tilesetBatch
  end
end

return DrawSystem
