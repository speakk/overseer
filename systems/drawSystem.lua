local Vector = require('libs/brinevector/brinevector')
local inspect = require('libs/inspect')
local commonComponents = require('components/common')
local utils = require('utils/utils')
local media = require('utils/media')

-- Create a draw System.
local DrawSystem = ECS.System({commonComponents.Position, commonComponents.Sprite})

function DrawSystem:init(mapSystem, jobSystem, camera, dayCycleSystem, lightSystem, spriteSystem)
  self.mapSystem = mapSystem
  self.jobSystem = jobSystem
  self.lightSystem = lightSystem
  self.spriteSystem = spriteSystem
  self.camera = camera
  self.dayCycleSystem = dayCycleSystem
end

function DrawSystem:draw()
  self.camera:draw(function(l,t,w,h)
    self.lightSystem:renderLights(l, t, w, h, function()
      local mapBatch = self.mapSystem:generateSpriteBatch(l, t, w, h)
      love.graphics.draw(mapBatch)
      local spriteBatch = self.spriteSystem:generateSpriteBatch(l, t, w, h)
      love.graphics.draw(spriteBatch)
    end)
  end)

  love.graphics.setColor(1, 1, 0)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10, 0, 1.3, 1.3)
  love.graphics.print("Amount of jobs: "..tostring(#self.jobSystem.pool.objects), 10, 40, 0, 1.3, 1.3)
end


return DrawSystem
