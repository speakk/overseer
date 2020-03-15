local Vector = require('libs.brinevector')
local bresenham = require('libs.bresenham')

local universe = require('models.universe')
local camera = require('models.camera')

local LightSystem = ECS.System({ECS.c.light})

local lightGradientImage = love.graphics.newImage("media/misc/light_gradient.png")
local lightCircleImage = love.graphics.newImage("media/misc/light_circle.png")
local lightCircleImageWidth = lightCircleImage:getWidth()
local lightCircleImageHeight = lightCircleImage:getHeight()
local lightCircleImageScale = 1

local universeSize = universe.getSize()
local cellSize = universe.getCellSize()
local lightCanvas = love.graphics.newCanvas(universeSize.x, universeSize.y+1)
local lightAmbientMixCanvas = love.graphics.newCanvas(universeSize.x+1, universeSize.y+1)

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
    light:give(ECS.c.light,
      { math.ceil(love.math.random()-0.5), math.ceil(love.math.random()-0.5), math.ceil(love.math.random()-0.5)}, 8)
    self:getWorld():addEntity(light)
  end
end

function calcShadows(self, lightPos, resolutionMultiplier)
  local shadowMap = {}
  for y = -1,(universeSize.y+1)*resolutionMultiplier do
    local row = {}
    for x = -1,(universeSize.x+1)*resolutionMultiplier do row[x] = 1 end -- 1 = Shadow
    shadowMap[y] = row
  end

  local lightRadius = 14 -- radius in tiles

  for _, coords in ipairs(universe.getCoordinatesAround(lightPos.x+0.5, lightPos.y+0.5, lightRadius)) do
    bresenham.los(lightPos.x*resolutionMultiplier,lightPos.y*resolutionMultiplier, coords.x*resolutionMultiplier, coords.y*resolutionMultiplier, function(x, y)
      local occluded = universe.isPositionOccluded(Vector(math.floor(x/resolutionMultiplier), math.floor(y/resolutionMultiplier)))

      if x < (universeSize.x+1)*resolutionMultiplier and
        x >= 0 and
        y >= 0 and
        y < (universeSize.y+1)*resolutionMultiplier then


        if not occluded then
          if not shadowMap[y-1] then print ("Oh dear", y-1, x-1) end
          shadowMap[y][x] = 0 -- add light
          return true
        else
          return false
        end
      end
    end)
  end

  return shadowMap
end

function LightSystem:gridUpdated()
  love.graphics.setCanvas( {lightCanvas, stencil = true } )
  love.graphics.clear(0,0,0,1)

  love.graphics.setColor(1,1,1,1)
  love.graphics.setBlendMode("add")

  local shadowResolutionMultiplier = 1

  for i, light in ipairs(self.pool) do
    local position = light.position.vector
    local gridPosition = universe.pixelsToGridCoordinates(position)

    love.graphics.stencil(function()
      local shadowMap = calcShadows(self, gridPosition, shadowResolutionMultiplier)
      for y = 1,#shadowMap do
        for x = 1,#shadowMap[y] do
          if shadowMap[y][x] == 1 then -- add shadow
            love.graphics.setColor(1, 0, 1, 1)
            love.graphics.rectangle('fill', x/shadowResolutionMultiplier, y/shadowResolutionMultiplier, shadowResolutionMultiplier, shadowResolutionMultiplier)
          end
        end
      end
    end,
    "replace", 1, false)

    love.graphics.setStencilTest("less", 1)

    local color = light.light.color
    love.graphics.setColor(color)
    love.graphics.draw(lightCircleImage,
    gridPosition.x-lightCircleImageWidth*lightCircleImageScale*0.5,
    gridPosition.y-lightCircleImageHeight*lightCircleImageScale*0.5,
    0, lightCircleImageScale, lightCircleImageScale)
    love.graphics.setStencilTest()
  end

  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas()
end

function LightSystem:timeOfDayChanged(timeOfDay)
  ambientColor = { 0.6+timeOfDay*0.4, 0.6+timeOfDay*0.4, 1.0, 1.0, 1.0 }
  self:mixAmbientAndLights()
end

local function drawAmbientLight()
  love.graphics.clear(1,1,1,1)
  love.graphics.setColor(unpack(ambientColor))
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
  love.graphics.setColor(1, 1, 1, 1)
  drawAmbientLight()
  drawLightCanvas()
  love.graphics.setCanvas()
  love.graphics.pop()
end

function LightSystem:renderLights(l, t, w, h, f) --luacheck: ignore
  f()

  love.graphics.setBlendMode("multiply", "premultiplied")
  love.graphics.draw(lightAmbientMixCanvas, 0, 0, 0, cellSize, cellSize)
  love.graphics.setBlendMode("alpha")

  local lightScale = 2
  local lightWidth = lightGradientImage:getWidth()*lightScale
  local lightHeight = lightGradientImage:getHeight()*lightScale

  local margin = 32

  -- Tiny bit of non-pixely glow as well. TODO: Cull based on t,w,h,f
  love.graphics.setBlendMode("add")
  for _, light in ipairs(self.pool) do
    local position = light.position.vector
    if universe.isPositionWithinArea(position, l-margin, t-margin, w+margin, h+margin) then
      local color = light.light.color
      love.graphics.setColor(unpack(color))
      love.graphics.draw(lightGradientImage, 16+position.x-lightWidth/2, 16+position.y-lightHeight/2,
      0, lightScale, lightScale)
    end
  end
  love.graphics.setBlendMode("alpha")
end

return LightSystem
