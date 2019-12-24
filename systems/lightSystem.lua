local Vector = require('libs.brinevector')

local utils = require('utils.utils')
local universe = require('models.universe')
local camera = require('models.camera')

local LightSystem = ECS.System("light", {ECS.Components.light})


local lightCircleImage = love.graphics.newImage("media/misc/light_circle.png")
local lightCircleImageWidth = lightCircleImage:getWidth()
local lightCircleImageHeight = lightCircleImage:getHeight()
local lightCircleImageScale = 1

--local singleLightCanvas = love.graphics.newCanvas(lightCircleImageWidth*lightCircleImageScale, lightCircleImageHeight*lightCircleImageScale)
local singleLightCanvas = love.graphics.newCanvas(lightCircleImageWidth*lightCircleImageScale, lightCircleImageHeight*lightCircleImageScale)
local universeSize = universe.getSize()
local cellSize = universe.getCellSize()
local lightCanvas = love.graphics.newCanvas(universeSize.x*cellSize, universeSize.y*cellSize)

local radialLightShader = love.graphics.newShader("shaders/radialLight")
local blendShader = love.graphics.newShader("shaders/blend_arrayimage")
blendShader:send("universeSize", { universeSize.x, universeSize.y })

local ambientColor = { 0.0, 0.0, 0.1, 1.0 }

function LightSystem:init()
  self.useShader = true

  -- love.graphics.setCanvas(singleLightCanvas)
  -- love.graphics:clear(0,0,0,0)
  -- love.graphics.setColor(1, 1, 1, 1)
  -- love.graphics.setShader(radialLightShader)
  -- love.graphics.draw(lightCircleImage, 0, 0, 0, 2, 2)
  -- love.graphics.setShader()
  -- love.graphics.setCanvas()
  --love.graphics.rectangle('fill', 0, 0, 100, 100)

end

function LightSystem:initializeTestLights()
  for _=1,30 do
    local light = ECS.Entity()
    light:give(ECS.Components.position,
      universe.snapPixelToGrid(Vector(love.math.random(universeSize.x*cellSize), love.math.random(universeSize.y*cellSize))))
    light:give(ECS.Components.sprite, "items.torch01")
    --light:give(ECS.Components.light,
    --{ love.math.random(), love.math.random(), love.math.random() }, love.math.random(200))
    light:give(ECS.Components.light, { 1, 1, 1 }, 8)
    self:getWorld():addEntity(light)
  end

  self:getWorld():flush()
  self:lightsOrMapChanged()
end

-- function LightSystem:getLights()
--   return self.pool
-- end

function LightSystem:lightsOrMapChanged()
  love.graphics.setCanvas(lightCanvas)
  love.graphics.clear()
  love.graphics.setColor(unpack(ambientColor))
  love.graphics.rectangle("fill", 0, 0, lightCanvas:getWidth(), lightCanvas:getHeight())
  love.graphics.setColor(1,1,1,1)
  love.graphics.setShader(radialLightShader)
  for _, light in ipairs(self.pool) do
    local position = light:get(ECS.Components.position).vector
    love.graphics.draw(lightCircleImage, position.x-lightCircleImageWidth*lightCircleImageScale*0.5, position.y-lightCircleImageHeight*lightCircleImageScale*0.5, 0, lightCircleImageScale, lightCircleImageScale)
  end
  love.graphics.setShader()
  love.graphics.setCanvas()
  blendShader:send("light_canvas", lightCanvas)
end

function LightSystem:timeOfDayChanged(timeOfDay)
  if self.useShader then
    --self.shader:send("dayTime", timeOfDay)
    ambientColor = { 0.0, 0.0, math.sin(timeOfDay), 1.0 }
    self:lightsOrMapChanged()
  end
end

function LightSystem:cameraScaleChanged(scale)
  if self.useShader then
    blendShader:send("scale", scale)
  end
end

function LightSystem:cameraPositionChanged(x, y)
  if self.useShader then
    --blendShader:send("transform", { x, y })
  end
end

function LightSystem:renderLights(l, t, w, h, f)
  local posX, posY = camera:getVisibleCorners()
  blendShader:send("transform", { posX-cellSize/2, posY-cellSize/2 })
  blendShader:send("light_canvas_size", { lightCanvas:getWidth(), lightCanvas:getHeight() })
  love.graphics.setShader(blendShader)
  f()
  --love.graphics.draw(lightCanvas)
  love.graphics.setShader()
end

-- function LightSystem:renderLights(l, t, w, h, f)
--   love.graphics.setShader(self.shader)
--   if self.useShader then
--     love.graphics.setShader(self.shader)
--     local transform = { -l, -t }
-- 
--     local allLights = self:getLights()
--     local visibleLights = {}
--     for _, light in ipairs(allLights) do
--       --local lightComponent = light:get(ECS.Components.light)
--       local position = light:get(ECS.Components.position).vector
--       local lightSize = Vector(128, 128)
--       if utils.withinBounds(position.x,
--         position.y,
--         position.x + lightSize.x,
--         position.y + lightSize.y,
--         l, t, l+w, t+h, lightSize.x) then
--         table.insert(visibleLights, light)
--       end
--     end
-- 
--     self.shader:send("num_lights", #visibleLights)
--     self.shader:send("transform", transform )
--     for i, light in ipairs(visibleLights) do
--       local lightComponent = light:get(ECS.Components.light)
--       local lightName = "lights[" .. i-1 .. "]";
--       local position = light:get(ECS.Components.position).vector
--       self.shader:send(lightName .. ".position", { position.x, position.y })
--       --self.shader:send(lightName .. ".diffuse", lightComponent.color)
--       self.shader:send(lightName .. ".power", lightComponent.power)
--     end
--   end
-- 
--   f()
-- 
--   love.graphics.setShader()
-- end

return LightSystem
