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
local lightCanvas = love.graphics.newCanvas((universeSize.x+1)*cellSize, (universeSize.y+1)*cellSize)
local lightAmbientMixCanvas = love.graphics.newCanvas((universeSize.x+1)*cellSize, (universeSize.y+1)*cellSize)

--local radialLightShader = love.graphics.newShader("shaders/radialLight")
--local blendShader = love.graphics.newShader("shaders/blend_arrayimage")
--if blendShader:hasUniform("universeSize") then blendShader:send("universeSize", { universeSize.x, universeSize.y }) end

local ambientColor = { 0.0, 0.0, 0.1, 1.0 }

function LightSystem:init()
  self.useShader = true
end

function LightSystem:initializeTestLights()
  for _=1,3 do
    local light = ECS.Entity()
    light:give(ECS.c.position,
      universe.snapPixelToGrid(
        Vector(love.math.random((universeSize.x-1)*cellSize)+cellSize, love.math.random((universeSize.y-1)*cellSize)+cellSize)))
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

function calcShadows(self, lightPos, resolutionMultiplier)
  local shadowMap = {}
  for y = -1,(universeSize.y+1)*resolutionMultiplier do
    local row = {}
    for x = -1,(universeSize.x+1)*resolutionMultiplier do row[x] = 1 end -- 1 = Shadow
    shadowMap[y] = row
  end

  local lightRadius = 14 -- radius in tiles

  for _, coords in ipairs(universe.getCoordinatesAround(lightPos.x, lightPos.y, lightRadius)) do
    bresenham.los(lightPos.x*resolutionMultiplier,lightPos.y*resolutionMultiplier, coords.x*resolutionMultiplier, coords.y*resolutionMultiplier, function(x, y)
      local occluded = universe.isPositionOccluded(Vector(math.floor(x/resolutionMultiplier), math.floor(y/resolutionMultiplier)))

      if x < universeSize.x*resolutionMultiplier and
        x >= 0 and
        y >= 0 and
        y < universeSize.y*resolutionMultiplier then


        if not occluded then
          if not shadowMap[y-1] then print ("Oh dear", y-1, x-1) end
          shadowMap[y-1][x-1] = 0 -- add light
          return true
        else
          return false
        end
      end
    end)
  end

  return shadowMap
end


function LightSystem:lightsOrMapChanged()
  love.graphics.setCanvas( {lightCanvas, stencil = true } )
  --love.graphics.clear(1,1,1,0)
  -- love.graphics.setColor(unpack(ambientColor))
  -- love.graphics.rectangle("fill", 0, 0, lightCanvas:getWidth(), lightCanvas:getHeight())

  love.graphics.setColor(1,1,1,1)
  --love.graphics.setBlendMode("add")
  --love.graphics.setShader(radialLightShader)

  local shadowResolutionMultiplier = 1

  for i, light in ipairs(self.pool) do
    local position = light:get(ECS.c.position).vector

    love.graphics.stencil(function()
      local shadowMap = calcShadows(self, universe.pixelsToGridCoordinates(position), shadowResolutionMultiplier)
      for y = 1,#shadowMap do
        for x = 1,#shadowMap[y] do
          if shadowMap[y][x] == 1 then -- add shadow
            love.graphics.setColor(1, 0, 1, 1)
            love.graphics.rectangle('fill', x*cellSize/shadowResolutionMultiplier, y*cellSize/shadowResolutionMultiplier, cellSize/shadowResolutionMultiplier, cellSize/shadowResolutionMultiplier)
          end
        end
      end
    end,
    "replace", 1, false)

    love.graphics.setStencilTest("less", 1)

    local color = light:get(ECS.c.light).color
    --radialLightShader:send("color", color)
    love.graphics.setColor(color)
    love.graphics.draw(lightCircleImage,
    position.x-lightCircleImageWidth*lightCircleImageScale*0.5,
    position.y-lightCircleImageHeight*lightCircleImageScale*0.5,
    0, lightCircleImageScale, lightCircleImageScale)
    love.graphics.setStencilTest()
  end



  --local cellSize = universe.getCellSize()

  --love.graphics.setBlendMode("alpha")
  --love.graphics.setShader()

  love.graphics.setCanvas()
  --if blendShader:hasUniform("ambientColor") then blendShader:send("ambientColor", ambientColor) end
  --if blendShader:hasUniform("light_canvas") then blendShader:send("light_canvas", lightCanvas) end
end

function LightSystem:timeOfDayChanged(timeOfDay)
  ambientColor = { 0.6+timeOfDay*0.4, 0.6+timeOfDay*0.4, 1.0, 1.0, 1.0 }
  -- if self.useShader then
  --   --self.shader:send("dayTime", timeOfDay)
  --   --if blendShader:hasUniform("ambientColor") then blendShader:send("ambientColor", ambientColor) end
  self:lightsOrMapChanged()
  self:mixAmbientAndLights()
  -- end
end

-- function LightSystem:cameraScaleChanged(scale)
--   if self.useShader then
--     if blendShader:hasUniform("scale") then blendShader:send("scale", scale) end
--   end
-- end
-- 
-- function LightSystem:cameraPositionChanged() --luacheck: ignore
--   local posX, posY = camera:getVisibleCorners()
--   if blendShader:hasUniform("transform") then blendShader:send("transform", { posX-cellSize/2, posY-cellSize/2 }) end
-- end
--

local function drawAmbientLight()
  love.graphics.clear(1,1,1,1)
  love.graphics.setColor(unpack(ambientColor))
  --love.graphics.setColor(1,1,1,1)
  love.graphics.rectangle('fill', 0,0, (universeSize.x+1)*cellSize, (universeSize.y+1)*cellSize)
end

local function drawLightCanvas()                          
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setBlendMode("add")
  love.graphics.draw(lightCanvas)
  love.graphics.setBlendMode("alpha")
end                                                 


function LightSystem:mixAmbientAndLights()
  love.graphics.push('all')
  love.graphics.reset()
  love.graphics.setScissor()
  love.graphics.setCanvas(lightAmbientMixCanvas)
  --love.graphics.clear(1, 1, 1, 1)
  love.graphics.setColor(1, 1, 1, 1)
  drawAmbientLight()
  drawLightCanvas()
  love.graphics.setCanvas()
  love.graphics.pop()
end

function LightSystem:renderLights(l, t, w, h, f) --luacheck: ignore
  f()

  love.graphics.setBlendMode("multiply", "premultiplied")
  --love.graphics.draw(lightCanvas)
  love.graphics.draw(lightAmbientMixCanvas)
  love.graphics.setBlendMode("alpha")

  -- local lightScale = 2
  -- local lightWidth = lightGradientImage:getWidth()*lightScale
  -- local lightHeight = lightGradientImage:getHeight()*lightScale

  -- love.graphics.setCanvas()
  -- love.graphics.setBlendMode("add")
  -- for _, light in ipairs(self.pool) do
  --   local position = light:get(ECS.c.position).vector
  --   local color = light:get(ECS.c.light).color
  --   love.graphics.setColor(unpack(color))
  --   love.graphics.draw(lightGradientImage, 16+position.x-lightWidth/2, 16+position.y-lightHeight/2,
  --     0, lightScale, lightScale)
  -- end
  -- love.graphics.setBlendMode("alpha")
end

return LightSystem
