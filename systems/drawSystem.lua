local Vector = require('libs/brinevector/brinevector')
local inspect = require('libs/inspect')
local commonComponents = require('components/common')
local utils = require('utils/utils')

-- Create a draw System.
local DrawSystem = ECS.System({commonComponents.Position, commonComponents.Draw})

local shader_code = [[
#define NUM_LIGHTS 32
struct Light {
    vec2 position;
    vec3 diffuse;
    float power;
};
extern Light lights[NUM_LIGHTS];
extern int num_lights;
extern vec2 transform;
extern float scale;
extern float dayTime;
const float constant = 1.0;
const float linear = 0.09;
const float quadratic = 0.032;
vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords){
    vec4 pixel = Texel(image, uvs);
    //pixel = pixel * vec4(0.4 * dayTime + 0.7, 0.4 * dayTime + 0.7, 1.0, 1);
    // Ambient light
    vec3 diffuse = vec3(dayTime*0.2, dayTime*0.2, dayTime*0.4);
    vec2 screen = love_ScreenSize.xy;

    for (int i = 0; i < num_lights; i++) {
        Light light = lights[i];
        float ratio = screen.x / screen.y;

        float distance = length((light.position + transform)*scale - screen_coords) / light.power / scale;
        float attenuation = 1.0 / (constant + linear * distance + quadratic * (distance * distance));
        diffuse += light.diffuse * attenuation;
    }
    diffuse = clamp(diffuse, 0.0, 1.0);
    //return pixel * vec4(0.4 * dayTime + 0.7, 0.4 * dayTime + 0.7, 1.0, 1) * vec4(diffuse, 1.0);
    return pixel * vec4(diffuse, 1.0);
}
]]

function DrawSystem:init(mapSystem, jobSystem, camera, dayCycleSystem, lightSystem)
  self.mapSystem = mapSystem
  --self.lightWorld = mapSystem:getLightWorld()
  self.jobSystem = jobSystem
  self.lightSystem = lightSystem
  self.camera = camera
  self.dayCycleSystem = dayCycleSystem
  self.shader = love.graphics.newShader(shader_code)

  mapTexture = love.graphics.newCanvas(128, 128)
  love.graphics.setCanvas(mapTexture)
  love.graphics.clear()
  --love.graphics.setBlendMode("alpha")
  love.graphics.setColor(0, 1, 0, 1)
  love.graphics.rectangle('fill', 0, 0, 100, 100)
  love.graphics.setCanvas()
  self.mapTexture = mapTexture
  self.cellQuad = love.graphics.newQuad(0, 0, 32, 32, mapTexture:getDimensions())
end

function DrawSystem:drawMap(l, t, w, h, map)
  local cellSize = self.mapSystem:getCellSize()
  local padding = self.mapSystem:getPadding()
  local mapColors = self.mapSystem:getMapColorArray()
  for rowNum, row in ipairs(map) do
    for cellNum, cellValue in ipairs(row) do --luacheck: ignore
      local drawMargin = cellSize
      local x1 = (cellNum * cellSize)
      local x2 = x1 + cellSize
      local y1 = rowNum * cellSize
      local y2 = y1 + cellSize
      if utils.withinBounds(x1, y1, x2, y2, l, t, l+w, t+h, drawMargin) then
        local color = mapColors[rowNum][cellNum]
        if color.grass == 1 then
          love.graphics.setColor(0.35, 0.4+(color.c*0.1), 0.1)
        else
          love.graphics.setColor(color.a*0.1+0.5, color.a*0.1+0.3, color.c*0.05+0.15)
        end
        love.graphics.draw(self.mapTexture, self.cellQuad, cellNum*cellSize, rowNum*cellSize)
        -- love.graphics.rectangle("fill",
        -- cellNum*cellSize,
        -- rowNum*cellSize,
        -- cellSize - padding,
        -- cellSize - padding
        -- )
      end
    end
  end
end

function DrawSystem:drawEntity(l, t, w, h, entity)
  local positionVector = entity:get(commonComponents.Position).vector
  local draw = entity:get(commonComponents.Draw)
  local sizeVector = draw.size
  if utils.withinBounds(positionVector.x,
    positionVector.y,
    positionVector.x + sizeVector.x,
    positionVector.y + sizeVector.y,
    l, t, l+w, t+h, sizeVector.x) then
    local color = draw.color
    local size = draw.size


    if entity:has(commonComponents.Job) then
      if entity:has(commonComponents.BluePrintJob) then
        local jobComponent = entity:get(commonComponents.Job)
        if jobComponent.finished then
          color[4] = 1.0
        else
          color[4] = 0.5
          love.graphics.setColor(1, 1, 1, 1)
          local progress = entity:get(commonComponents.BluePrintJob).buildProgress
          love.graphics.print(" " .. string.format("%d", progress) .. "%", positionVector.x, positionVector.y)
        end
      end
    end

    love.graphics.setColor(color[1], color[2], color[3], color[4])
    love.graphics.rectangle("fill",
    positionVector.x,
    positionVector.y,
    size.x, size.y)

    if entity:has(commonComponents.Amount) then
      love.graphics.setColor(1, 1, 1)
      love.graphics.print(" " .. tostring(entity:get(commonComponents.Amount).amount),
      positionVector.x+10, positionVector.y+10)
    end

    if DEBUG then
      if (entity:has(commonComponents.Path)) then
        local pathComponent = entity:get(commonComponents.Path)
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

function DrawSystem:draw()
  self.camera:draw(function(l,t,w,h)
    love.graphics.setShader(self.shader)
    self.shader:send("dayTime", self.dayCycleSystem:getTimeOfDay())
    --local transformX, transformY = self.camera:getViewMatrix()
    local transform = { -l, -t }
    local scale = self.camera:getScale()

    local lights = self.lightSystem:getLights()
    self.shader:send("num_lights", #lights)
    self.shader:send("transform", transform )
    self.shader:send("scale", scale)
    print(l, t, w, h, transformX, transformY)
    for i, light in ipairs(lights) do
      local lightComponent = light:get(commonComponents.Light)
      local lightName = "lights[" .. i-1 .. "]";
      local position = light:get(commonComponents.Position).vector
      self.shader:send(lightName .. ".position", { position.x, position.y })
      self.shader:send(lightName .. ".diffuse", lightComponent.color)
      self.shader:send(lightName .. ".power", lightComponent.power)
      --print("Sent", lightName .. ".position", position.x, position.y, inspect(lightComponent.color), lightComponent.power)
    end

    self:drawMap(l, t, w, h, self.mapSystem:getMap())
    for _, entity in ipairs(self.pool.objects) do
      self:drawEntity(l, t, w, h, entity)
    end

    love.graphics.setShader()
  end)

  love.graphics.setColor(1, 1, 0)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10, 0, 1.3, 1.3)
  love.graphics.print("Amount of jobs: "..tostring(#self.jobSystem.pool.objects), 10, 40, 0, 1.3, 1.3)
end


return DrawSystem
