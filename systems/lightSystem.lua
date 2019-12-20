local Vector = require('libs/brinevector/brinevector')

local utils = require('utils/utils')

local LightSystem = ECS.System("light", {ECS.Components.light})

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

function LightSystem:init()
  self.useShader = true
  self.shader = love.graphics.newShader(shader_code)
end

function LightSystem:initializeTestLights()
  for _=1,31 do
    local light = ECS.Entity()
    light:give(ECS.Components.position,
      Vector(love.math.random(love.graphics.getWidth()*2), love.math.random(love.graphics.getHeight()*2)))
    light:give(ECS.Components.sprite, "items.torch01")
    --light:give(ECS.Components.light,
    --{ love.math.random(), love.math.random(), love.math.random() }, love.math.random(200))
    light:give(ECS.Components.light, { 1, 1, 1 }, 8)
    self:getWorld():addEntity(light)
  end
end

function LightSystem:getLights()
  return self.pool
end

function LightSystem:timeOfDayChanged(timeOfDay)
  if self.useShader then
    self.shader:send("dayTime", timeOfDay)
  end
end

function LightSystem:cameraScaleChanged(scale)
  if self.useShader then
    self.shader:send("scale", scale)
  end
end

function LightSystem:renderLights(l, t, w, h, f)
  love.graphics.setShader(self.shader)
  if self.useShader then
    love.graphics.setShader(self.shader)
    local transform = { -l, -t }

    local allLights = self:getLights()
    local visibleLights = {}
    for _, light in ipairs(allLights) do
      --local lightComponent = light:get(ECS.Components.light)
      local position = light:get(ECS.Components.position).vector
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
    for i, light in ipairs(visibleLights) do
      local lightComponent = light:get(ECS.Components.light)
      local lightName = "lights[" .. i-1 .. "]";
      local position = light:get(ECS.Components.position).vector
      self.shader:send(lightName .. ".position", { position.x, position.y })
      --self.shader:send(lightName .. ".diffuse", lightComponent.color)
      self.shader:send(lightName .. ".power", lightComponent.power)
    end
  end

  f()

  love.graphics.setShader()
end

return LightSystem
