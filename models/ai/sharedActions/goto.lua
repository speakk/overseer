local BehaviourTree = require('libs.behaviourtree')
local universe = require('models.universe')

return function()
  return BehaviourTree.Task:new({
    run = function(task, blackboard)
      if blackboard.actor.path then
        if blackboard.actor.path.finished then
          blackboard.actor:remove("path")
          return task:success()
        else
          -- if universe.isInPosition(from, to, true) then
          --   return task:success()
          -- end
          return task:running()
        end
      end

      if not blackboard.target then
        return task:fail()
      end

      local from = universe.pixelsToGridCoordinates(blackboard.actor.position.vector)
      local to = universe.pixelsToGridCoordinates(blackboard.target.position.vector)

      if universe.isInPosition(from, to, true) then
        return task:success()
      end

      blackboard.actor:give("path", nil, nil, from.x, from.y, to.x, to.y)
      return task:running()
    end
  })
end
