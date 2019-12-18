local commonComponents = require('components/common')
local Vector = require('libs/brinevector/brinevector')

local LightSystem = ECS.System({commonComponents.Light})

function LightSystem:init()
end

function LightSystem:initializeTestLights()
  for i=1,31 do
    local light = ECS.Entity()
    light:give(commonComponents.Position, Vector(love.math.random(love.graphics.getWidth()*2), love.math.random(love.graphics.getHeight()*2)))
    --light:give(commonComponents.Light, { love.math.random(), love.math.random(), love.math.random() }, love.math.random(200))
    light:give(commonComponents.Light, { 1, 1, 1 }, 8)
    light:apply()
    self:getInstance():addEntity(light)
  end
end

function LightSystem:getLights()
  return self.pool.objects
end

return LightSystem
