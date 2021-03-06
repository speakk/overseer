local inspect = require 'libs.inspect'
local Class = require 'libs.hump.class'

return Class({
  -- STATIC
  loadTypes = function()
    local weightRunnersDir = "models/ai/weightRunners"

    return functional.reduce(love.filesystem.getDirectoryItems(weightRunnersDir), function(result, fileName)
      local name = string.gsub(fileName, ".lua", "")
      print("Adding to weight runners", name)
      result[name] = require(string.gsub(weightRunnersDir .. "/" .. name, "/", "."))
      return result
    end, {})
  end,
  init = function(self, entity, world, weightTasks)
    self.weightTasks = weightTasks
    self.entity = entity
    self.world = world
  end,
  run = function(self, treeDt)
    local sortedWeightTasks = table.stable_sort(table.copy(self.weightTasks), function(a, b)
      --print(inspect(a))
      local pointsA = a.points or a.getPoints(self.entity)
      local pointsB = b.points or b.getPoints(self.entity)
      return pointsA > pointsB
    end)
    -- local highestScoring = functional.reduce(self.weightTasks, function(result, task)
    --   local points = task.points or task.getPoints(self.entity)
    --   --print("points", points)
    --   if points > result.points then
    --     result.points = points
    --     result.behaviourTree = task.behaviourTree
    --   end

    --   return result
    -- end,
    -- { points = 0, behaviourTree = nil })

    -- TODO: Consider if we need to save "currentlyRunning",
    -- and then recreate and destroy trees as they're being switched to!
    --print(inspect(highestScoring.behaviourTree))
    --highestScoring.behaviourTree:run(treeDt)
    for _, weightTask in ipairs(sortedWeightTasks) do
      if weightTask.behaviourTree:run(treeDt) then
        break
      end
    end
  end
})

