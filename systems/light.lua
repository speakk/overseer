local Vector = require('libs.brinevector')
local bresenham = require('libs.bresenham')

local universe = require('models.universe')
local camera = require('models.camera')

local LightSystem = ECS.System({ECS.c.light})


local lightGradientImage = love.graphics.newImage("media/misc/light_gradient.png")
local lightCircleImage = love.graphics.newImage("media/misc/light_circle.png")
local lightCircleImageWidth = lightCircleImage:getWidth()
local lightCircleImageHeight = lightCircleImage:getHeight()
local lightCircleImageScale = 2

local universeSize = universe.getSize()
local cellSize = universe.getCellSize()
local lightCanvas = love.graphics.newCanvas(universeSize.x*cellSize, universeSize.y*cellSize)

local radialLightShader = love.graphics.newShader("shaders/radialLight")
local blendShader = love.graphics.newShader("shaders/blend_arrayimage")
if blendShader:hasUniform("universeSize") then blendShader:send("universeSize", { universeSize.x, universeSize.y }) end

local ambientColor = { 0.0, 0.0, 0.1, 1.0 }

function LightSystem:init()
  self.useShader = true
end

function LightSystem:initializeTestLights()
  for _=1,50 do
    local light = ECS.Entity()
    light:give(ECS.c.position,
      universe.snapPixelToGrid(
        Vector(love.math.random(universeSize.x*cellSize)+32, love.math.random(universeSize.y*cellSize)+32)))
    light:give(ECS.c.sprite, "items.torch01")
    --light:give(ECS.c.light,
    --{ love.math.random(), love.math.random(), love.math.random() }, love.math.random(200))
    light:give(ECS.c.light,
      { math.ceil(love.math.random()-0.5), math.ceil(love.math.random()-0.5), math.ceil(love.math.random()-0.5)}, 8)
    self:getWorld():addEntity(light)
  end

  self:lightsOrMapChanged()
end

-- function LightSystem:getLights()
--   return self.pool
-- end

function calcShadows(self)
  xs = {1, universeSize.x}
  ys = {1, universeSize.y}

  local shadowMap = {}
  for y = 1,universeSize.x do
    local row = {}
    for x = 1,universeSize.y do row[x] = 1 end
    shadowMap[y] = row
  end

  for x in ipairs({1, universeSize.x}) do
    for y = 1,universeSize.y do
      for _, light in ipairs(self.pool) do
        local lightPos = light:get(ECS.c.position).vector
        bresenham.los(x,y,lightPos.x,lightPos.y, function(x, y)
          local available = universe.isCellAvailable(Vector(x, y))
          if available then
            shadowMap[y][x] = 0
            return true
          else
            return false
          end
        end)
      end
    end
  end

  return shadowMap
end


function LightSystem:lightsOrMapChanged()
  love.graphics.setCanvas(lightCanvas)
  love.graphics.clear()
  love.graphics.setColor(unpack(ambientColor))
  love.graphics.rectangle("fill", 0, 0, lightCanvas:getWidth(), lightCanvas:getHeight())
  love.graphics.setColor(1,1,1,0)
  love.graphics.setBlendMode("add")
  love.graphics.setShader(radialLightShader)
  for _, light in ipairs(self.pool) do
    local position = light:get(ECS.c.position).vector
    local color = light:get(ECS.c.light).color
    radialLightShader:send("color", color)
    love.graphics.draw(lightCircleImage,
      position.x-lightCircleImageWidth*lightCircleImageScale*0.5,
      position.y-lightCircleImageHeight*lightCircleImageScale*0.5,
      0, lightCircleImageScale, lightCircleImageScale)
  end

  local shadowMap = calcShadows(self)

  local cellSize = universe.getCellSize()

  for y = 1,#shadowMap do
    for x = 1,#shadowMap[y] do
      love.graphics.setColor(1, 0, 0, 1)
      love.graphics.rectangle('fill', x*cellSize, y*cellSize, cellSize, cellSize)
    end
  end

  love.graphics.setBlendMode("alpha")
  love.graphics.setShader()
  love.graphics.setCanvas()
  if blendShader:hasUniform("ambientColor") then blendShader:send("ambientColor", ambientColor) end
  if blendShader:hasUniform("light_canvas") then blendShader:send("light_canvas", lightCanvas) end
end

function LightSystem:timeOfDayChanged(timeOfDay)
  if self.useShader then
    --self.shader:send("dayTime", timeOfDay)
    ambientColor = { 0.6+timeOfDay*0.4, 0.6+timeOfDay*0.4, 1.0, 1.0 }
    if blendShader:hasUniform("ambientColor") then blendShader:send("ambientColor", ambientColor) end
    self:lightsOrMapChanged()
  end
end

function LightSystem:cameraScaleChanged(scale)
  if self.useShader then
    if blendShader:hasUniform("scale") then blendShader:send("scale", scale) end
  end
end

function LightSystem:cameraPositionChanged() --luacheck: ignore
  local posX, posY = camera:getVisibleCorners()
  if blendShader:hasUniform("transform") then blendShader:send("transform", { posX-cellSize/2, posY-cellSize/2 }) end
end

function LightSystem:renderLights(l, t, w, h, f) --luacheck: ignore
  if blendShader:hasUniform("light_canvas_size") then
    blendShader:send("light_canvas_size", { lightCanvas:getWidth(), lightCanvas:getHeight() })
  end
  love.graphics.setShader(blendShader)
  f()
  --love.graphics.draw(lightCanvas)
  love.graphics.setShader()

  local lightScale = 2
  local lightWidth = lightGradientImage:getWidth()*lightScale
  local lightHeight = lightGradientImage:getHeight()*lightScale

  love.graphics.setCanvas()
  love.graphics.setBlendMode("add")
  for _, light in ipairs(self.pool) do
    local position = light:get(ECS.c.position).vector
    local color = light:get(ECS.c.light).color
    love.graphics.setColor(unpack(color))
    love.graphics.draw(lightGradientImage, 16+position.x-lightWidth/2, 16+position.y-lightHeight/2,
      0, lightScale, lightScale)
  end
  love.graphics.setBlendMode("alpha")
end

return LightSystem
