local luabt = require('libs.luabt')
local lume = require('libs.lume') --luacheck: ignore

local tasks = {
  work = require('models.ai.tasks.work').createTree,
  idle = require('models.ai.tasks.idle').createTree,
  eat = require('models.ai.tasks.eat').createTree,
  fetch = require('models.ai.tasks.fetch').createTree,
  bluePrint = require('models.ai.tasks.bluePrint').createTree,
  destruct = require('models.ai.tasks.destruct').createTree
}

local function createWeightRunner(entity, world, type)
  local weightTasks = {
    {
      behaviourTree = tasks.idle(entity, world), -- TODO: Obviously make this "eat"
      getPoints = function()
        return 100 - entity.satiety.value
      end
    },
    {
      behaviourTree = tasks.work(entity, world),
      getPoints = function()
        return 80
      end
    },
    {
      behaviourTree = tasks.idle(entity, world),
      points = 40
    }
  }

  return {
    run = function(treeDt)
      local highestScoring = functional.reduce(weightTasks, function(result, task)
        local points = task.points or task.getPoints(entity)
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
  }
end

return {
  createWeightRunner = createWeightRunner
}
