local Vector = require('libs/brinevector/brinevector')
local inspect = require('libs/inspect')
local components = require('libs/concord').components
local utils = require('utils/utils')
local media = require('utils/media')

-- Create a draw System.
local DrawSystem = ECS.System("draw", {components.position, components.sprite})

function DrawSystem:init()
end

function DrawSystem:registerSpriteBatchGenerator(callBack)
  table.insert(self.spriteBatchGenerators, callBack)
end

function DrawSystem:draw()
  self.camera:draw(function(l,t,w,h)
    self.lightSystem:renderLights(l, t, w, h, function()
      for _, spriteBatchGenerator in ipairs(self.spriteBatchGenerators) do
        local batch = spriteBatchGenerator(l, t, w, h)
        love.graphics.draw(batch)
      end
      -- local mapBatch = self.mapSystem:generateSpriteBatch(l, t, w, h)
      -- love.graphics.draw(mapBatch)
      -- local spriteBatch = self.spriteSystem:generateSpriteBatch(l, t, w, h)
      -- love.graphics.draw(spriteBatch)
    end)
  end)

  love.graphics.setColor(1, 1, 0)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10, 0, 1.3, 1.3)
  --love.graphics.print("Amount of jobs: "..tostring(#self.jobSystem.pool.objects), 10, 40, 0, 1.3, 1.3)
end


return DrawSystem
