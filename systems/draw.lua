local camera = require('models.camera')

-- Create a draw System.
local DrawSystem = ECS.System({ECS.Components.position, ECS.Components.sprite})

function DrawSystem:init()
  self.spriteBatchGenerators = {}
  self.guiDrawGenerators = {}
  self.guiCameraDrawGenerators = {}
end

function DrawSystem:registerSpriteBatchGenerator(callee, callBack)
  table.insert(self.spriteBatchGenerators, { callee = callee, callBack = callBack})
end

function DrawSystem:registerGUIDrawGenerator(callee, callBack, inCamera)
  if inCamera then
    table.insert(self.guiCameraDrawGenerators, { callee = callee, callBack = callBack})
  else
    table.insert(self.guiDrawGenerators, { callee = callee, callBack = callBack})
  end
end

function DrawSystem:draw()
  love.graphics.setColor(1, 1, 1, 1)
  camera:draw(function(l,t,w,h)
    -- TODO: Do not use getWorld getSystem here, figure out a better way
    self:getWorld():getSystem(ECS.Systems.light):renderLights(l, t, w, h, function()
      for _, spriteBatchGenerator in ipairs(self.spriteBatchGenerators) do
        local batch = spriteBatchGenerator.callBack(spriteBatchGenerator.callee, l, t, w, h)
        love.graphics.draw(batch)
      end
    end)

    for _, guiDrawGenerator in ipairs(self.guiCameraDrawGenerators) do
      guiDrawGenerator.callBack(guiDrawGenerator.callee, l, t, w, h)
    end
    -- local mapBatch = self.mapSystem:generateSpriteBatch(l, t, w, h)
    -- love.graphics.draw(mapBatch)
    -- local spriteBatch = self.spriteSystem:generateSpriteBatch(l, t, w, h)
    -- love.graphics.draw(spriteBatch)
  end)

  for _, guiDrawGenerator in ipairs(self.guiDrawGenerators) do
    guiDrawGenerator.callBack(guiDrawGenerator.callee)
  end

  love.graphics.setColor(1, 1, 0)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10, 0, 1.3, 1.3)
  --love.graphics.print("Amount of jobs: "..tostring(#self.jobSystem.pool), 10, 40, 0, 1.3, 1.3)
end


return DrawSystem