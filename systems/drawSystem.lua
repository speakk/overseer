local Vector = require('libs/brinevector/brinevector')
local inspect = require('libs/inspect')
local commonComponents = require('components/common')
local utils = require('utils/utils')
local media = require('utils/media')

-- Create a draw System.
local DrawSystem = ECS.System({commonComponents.Position, commonComponents.Sprite})

local shader_code = [[
#define NUM_LIGHTS 32

uniform ArrayImage MainTex;

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
void effect(){
    vec4 color = VaryingColor;
    vec3 uvs = VaryingTexCoord.xyz; // includes the layer index as the z component
    vec2 screen_coords = love_PixelCoord;

    // Ambient light
    vec3 diffuse = vec3(dayTime*0.4+0.6, dayTime*0.4+0.6, dayTime*0.1+0.9);
    vec2 screen = love_ScreenSize.xy;

    for (int i = 0; i < num_lights; i++) {
        Light light = lights[i];
        float ratio = screen.x / screen.y;

        float distance = length((light.position + transform)*scale - screen_coords) / light.power / scale;
        if (distance < light.power*2) {
          float attenuation = 1.0 / (constant + linear * distance + quadratic * (distance * distance));
          diffuse += attenuation;
        } else {

        }
    }
    diffuse = clamp(diffuse, 0.0, 1.0);
    love_PixelColor = Texel(MainTex, uvs) * vec4(diffuse, 1.0);
}
]]

function DrawSystem:init(mapSystem, jobSystem, camera, dayCycleSystem, lightSystem, settlerSystem)
  self.mapSystem = mapSystem
  --self.lightWorld = mapSystem:getLightWorld()
  self.jobSystem = jobSystem
  self.lightSystem = lightSystem
  self.settlerSystem = settlerSystem
  self.camera = camera
  self.dayCycleSystem = dayCycleSystem
  self.shader = love.graphics.newShader(shader_code)

  self.useShader = true

end


-- function DrawSystem:drawEntity(l, t, w, h, entity)
--   local positionVector = entity:get(commonComponents.Position).vector
--   local draw = entity:get(commonComponents.Draw)
--   local sizeVector = draw.size
--   if utils.withinBounds(positionVector.x,
--     positionVector.y,
--     positionVector.x + sizeVector.x,
--     positionVector.y + sizeVector.y,
--     l, t, l+w, t+h, sizeVector.x) then
--     local color = draw.color
--     local size = draw.size
-- 
-- 
--     if entity:has(commonComponents.Job) then
--       if entity:has(commonComponents.BluePrintJob) then
--         local jobComponent = entity:get(commonComponents.Job)
--         if jobComponent.finished then
--           color[4] = 1.0
--         else
--           color[4] = 0.5
--           love.graphics.setColor(1, 1, 1, 1)
--           local progress = entity:get(commonComponents.BluePrintJob).buildProgress
--           love.graphics.print(" " .. string.format("%d", progress) .. "%", positionVector.x, positionVector.y)
--         end
--       end
--     end
-- 
--     -- love.graphics.setColor(color[1], color[2], color[3], color[4])
--     -- love.graphics.rectangle("fill",
--     -- positionVector.x,
--     -- positionVector.y,
--     -- size.x, size.y)
-- 
--     -- if entity:has(commonComponents.Amount) then
--     --   love.graphics.setColor(1, 1, 1)
--     --   love.graphics.print(" " .. tostring(entity:get(commonComponents.Amount).amount),
--     --   positionVector.x+10, positionVector.y+10)
--     -- end
-- 
--     if DEBUG then
--       if (entity:has(commonComponents.Path)) then
--         local pathComponent = entity:get(commonComponents.Path)
--         if pathComponent.path then
--           local vertices = {}
--           for node, count in pathComponent.path:nodes() do --luacheck: ignore
--             local pixelPosition = self.mapSystem:gridPositionToPixels(
--             Vector(node:getX(), node:getY()), 'center', 2
--             )
--             table.insert(vertices, pixelPosition.x)
--             table.insert(vertices, pixelPosition.y)
--           end
--           love.graphics.setColor(1, 1, 1)
--           love.graphics.line(vertices)
--         end
--       end
--     end
--   end
-- end

function DrawSystem:draw()
  self.camera:draw(function(l,t,w,h)
    love.graphics.setShader(self.shader)
    if self.useShader then
      self.shader:send("dayTime", self.dayCycleSystem:getTimeOfDay())
      --local transformX, transformY = self.camera:getViewMatrix()
      local transform = { -l, -t }
      local scale = self.camera:getScale()

      local allLights = self.lightSystem:getLights()
      local visibleLights = {}
      for i, light in ipairs(allLights) do
        local lightComponent = light:get(commonComponents.Light)
        local position = light:get(commonComponents.Position).vector
        local lightSize = Vector(128, 128)
        if utils.withinBounds(position.x,
          position.y,
          position.x + lightSize.x,
          position.y + lightSize.y,
          l, t, l+w, t+h, lightSize.x) then
          table.insert(visibleLights, light)
        end
      end

      self.shader:send("num_lights", #visibleLights)
      self.shader:send("transform", transform )
      self.shader:send("scale", scale)
      for i, light in ipairs(visibleLights) do
        local lightComponent = light:get(commonComponents.Light)
        local lightName = "lights[" .. i-1 .. "]";
        local position = light:get(commonComponents.Position).vector
        self.shader:send(lightName .. ".position", { position.x, position.y })
        --self.shader:send(lightName .. ".diffuse", lightComponent.color)
        self.shader:send(lightName .. ".power", lightComponent.power)
      end
    end

    --self:drawMap(l, t, w, h, self.mapSystem:getMap())
    local spriteBatch = self.mapSystem:generateSpriteBatch(l, t, w, h)
    love.graphics.draw(spriteBatch)
    local entitySpriteBatch = self.settlerSystem:generateSpriteBatch(l, t, w, h)
    love.graphics.draw(entitySpriteBatch)
    -- for _, entity in ipairs(self.pool.objects) do
    --   self:drawEntity(l, t, w, h, entity)
    -- end

    love.graphics.setShader()
  end)

  love.graphics.setColor(1, 1, 0)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10, 0, 1.3, 1.3)
  love.graphics.print("Amount of jobs: "..tostring(#self.jobSystem.pool.objects), 10, 40, 0, 1.3, 1.3)
end


return DrawSystem
