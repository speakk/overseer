local Vector = require('libs.brinevector')
local Timer = require('libs.hump.timer')
local bresenham = require('libs.bresenham')
local Gamestate = require("libs.hump.gamestate")

local positionUtils = require('utils.position')
local entityFinder = require('models.entityFinder')

local LightSystem = ECS.System({
  pool = { "light", "position", "active" },
  occluders = { "onMap", "position", "occluder", "active" }
})

local lightGradientImage = love.graphics.newImage("media/misc/light_gradient.png")
local lightCircleImage = love.graphics.newImage("media/misc/light_circle.png")
local lightCircleImageWidth = lightCircleImage:getWidth()
local lightCircleImageHeight = lightCircleImage:getHeight()
local lightCircleImageScale = 1

local lightCanvas
local lightAmbientMixCanvas

local ambientColor = { 0.0, 0.0, 0.1, 1.0 }

local occluderMap = {}

function onOccluderEntityAdded(_, entity)
  local posString = entityFinder.getPositionStringFromEntity(entity)

  occluderMap[posString] = 1
end

function onOccluderEntityRemoved(_, entity)
  if not entity.position then return end
  local posString = entityFinder.getPositionStringFromEntity(entity)

  occluderMap[posString] = 0
end

function isPositionOccluded(gridPosition)
  local posString = gridPosition.x .. ":" .. gridPosition.y

  if occluderMap[posString] == 1 then
    return true
  end

  return false
end

function LightSystem:init()
  self.useShader = true

  self.mapConfig = Gamestate.current().mapConfig

  lightCanvas = love.graphics.newCanvas(self.mapConfig.width, self.mapConfig.height+1)
  lightAmbientMixCanvas = love.graphics.newCanvas(self.mapConfig.width+1, self.mapConfig.height+1)
  lightAmbientMixCanvas:setFilter("nearest", "linear")

  self.occluders.onEntityAdded = function(_, entity)
    onOccluderEntityAdded(_, entity)
    self:gridUpdated()
  end

  self.occluders.onEntityRemoved = function(_, entity)
    onOccluderEntityRemoved(_, entity)
    self:gridUpdated()
  end

  self.pool.onEntityAdded = function(_, entity)
    self:gridUpdated()
  end

  self.pool.onEntityRemoved = function(_, entity)
    self:gridUpdated()
  end
end

local function drawAmbientLight(self)
  love.graphics.clear(1,1,1,1)
  love.graphics.setColor(unpack(ambientColor))
  love.graphics.rectangle('fill', 0,0, (self.mapConfig.width+1)*self.mapConfig.cellSize, (self.mapConfig.height+1)*self.mapConfig.cellSize)
end

local function drawLightCanvas()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setBlendMode("add")
  love.graphics.draw(lightCanvas)
  love.graphics.setBlendMode("alpha")
end

local function mixAmbientAndLights(self)
  love.graphics.push('all')
  love.graphics.reset()
  love.graphics.setScissor()
  love.graphics.setCanvas(lightAmbientMixCanvas)
  love.graphics.setColor(1, 1, 1, 1)
  drawAmbientLight(self)
  drawLightCanvas()
  love.graphics.setCanvas()
  love.graphics.pop()
end

function LightSystem:initializeTestLights()
  local mapSize = Vector(self.mapConfig.width, self.mapConfig.height)
  for _=1,6 do
    local light = ECS.Entity()
    local position = Vector(love.math.random(mapSize.x), love.math.random(mapSize.y))
    if positionUtils.isPositionWalkable(position) then
      light:give("position", positionUtils.gridPositionToPixels(position))
      light:give("sprite", "items.torch01")
      light:give("light",
      { math.ceil(love.math.random()-0.5), math.ceil(love.math.random()-0.5), math.ceil(love.math.random()-0.5)}, 8)
      self:getWorld():addEntity(light)
    end
  end
end

local function calcShadows(self, lightPos, resolutionMultiplier, lightRadius)
  local mapSize = Vector(lightRadius*2, lightRadius*2)
  --local mapSize = Vector(self.mapConfig.width, self.mapConfig.height)
  local shadowMap = {}
  for y = 1,(mapSize.y+1)*resolutionMultiplier do
    local row = {}
    for x = 1,(mapSize.x+1)*resolutionMultiplier do row[x] = 1 end -- 1 = Shadow
    shadowMap[y] = row
  end

  for _, coords in ipairs(positionUtils.getCoordinatesAround(lightPos.x, lightPos.y, lightRadius)) do
    bresenham.los(lightPos.x*resolutionMultiplier,lightPos.y*resolutionMultiplier,
    coords.x*resolutionMultiplier, coords.y*resolutionMultiplier, function(origX, origY)
      local x = origX - lightPos.x + 1 + mapSize.x/2
      local y = origY - lightPos.y + 1 + mapSize.y/2
      --print("xy", x, y, lightPos.x, lightPos.y, origX, origY)

      --if shadowMap[y][x] == 1 then return true end

      local occluded = isPositionOccluded(
      Vector(math.floor(origX/resolutionMultiplier), math.floor(origY/resolutionMultiplier))
      )

      if not occluded then
        shadowMap[y][x] = 0 -- add light
        return true
      else
        return false
      end
    end)
  end

  return shadowMap
end

-- TODO: Make a buffer for this (say 20ms) where if this gets updated multiple times in a row, it only gets actually re-rendered at the end of the 20ms period
local bufferLength = 0.2
local bufferTimer = nil
function LightSystem:gridUpdated()
  if bufferTimer then return end

  bufferTimer = Timer.after(bufferLength, function()
    print("Grid updated so drawing lights")
    love.graphics.setCanvas( {lightCanvas, stencil = true } )
    love.graphics.clear(0,0,0,1)

    love.graphics.setColor(1,1,1,1)
    love.graphics.setBlendMode("add")


    local function drawStencil(self, gridPosition, shadowResolutionMultiplier, lightRadius)
      local shadowMap = calcShadows(self, gridPosition, shadowResolutionMultiplier, lightRadius)
      for y = 1,#shadowMap do
        for x = 1,#shadowMap[y] do
          if shadowMap[y][x] == 1 then -- add shadow
            love.graphics.setColor(1, 0, 1, 1)
            love.graphics.rectangle('fill', x+gridPosition.x-lightRadius-1/shadowResolutionMultiplier, y+gridPosition.y-lightRadius-1/shadowResolutionMultiplier,
            shadowResolutionMultiplier, shadowResolutionMultiplier)
          end
        end
      end
    end

    local shadowResolutionMultiplier = 1

    for _, light in ipairs(self.pool) do
      local position = light.position.vector
      local gridPosition = positionUtils.pixelsToGridCoordinates(position)
      local lightRadius = 9

      love.graphics.stencil(function()
        drawStencil(self, gridPosition, shadowResolutionMultiplier, lightRadius)
      end,
      "replace", 1, false)

      --drawStencil(self, gridPosition, shadowResolutionMultiplier, lightRadius)

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

    bufferTimer = nil
  end)
end

function LightSystem:timeChanged(time, timeOfDay) --luacheck: ignore
  local lightLevel = math.sin((timeOfDay-0.25)*math.pi*2)
  ambientColor = { 0.6+lightLevel*0.4, 0.6+lightLevel*0.4, 1.0, 1.0, 1.0 }
  mixAmbientAndLights(self)
end


function LightSystem:renderLights(l, t, w, h, f) --luacheck: ignore
  f()

  local cellSize = self.mapConfig.cellSize

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
    if positionUtils.isPositionWithinArea(position, l-margin, t-margin, w+margin, h+margin) then
      local color = light.light.color
      love.graphics.setColor(unpack(color))
      love.graphics.draw(lightGradientImage, 16+position.x-lightWidth/2, 16+position.y-lightHeight/2,
      0, lightScale, lightScale)
    end
  end
  love.graphics.setBlendMode("alpha")
end

return LightSystem
