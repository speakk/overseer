local Class = require 'libs.hump.class'

return Class({
  -- STATIC
  loadTypes = function()
    local weightRunnersDir = "model/ai/weightRunners"

    return functional.reduce(love.filesystem.getDirectoryItems(weightRunnersDir), function(result, fileName)
      local name = string.gsub(fileName, ".lua", "")
      result[name] = require(string.gsub(weightRunnersDir, "/", "."))
      return result
    end, {})
  end,
  init = function(self, entity, world, weightTasks)
    self.weightTasks = weightTasks
    self.entity = entity
    self.world = world
  end,
  run = function(self, treeDt)
    local highestScoring = functional.reduce(self.weightTasks, function(result, task)
      local points = task.points or task.getPoints(self.entity)
      --print("points", points)
      if points > result.points then
        result.points = points
        result.behaviourTree = task.behaviourTree
      end

      return result
    end,
    { points = 0, behaviourTree = nil })

    -- TODO: Consider if we need to save "currentlyRunning",
    -- and then recreate and destroy trees as they're being switched to!
    highestScoring.behaviourTree(treeDt)
  end
})

