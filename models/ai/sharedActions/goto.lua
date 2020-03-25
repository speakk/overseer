local BehaviourTree = require('libs.behaviourtree')
local positionUtils = require('utils.position')

return function()
  return BehaviourTree.Task:new({
    run = function(task, blackboard)
      if blackboard.actor.path then
        if blackboard.actor.path.finished then
          blackboard.actor:remove("path")
          return task:success()
        else
          -- if positionUtils.isInPosition(from, to, true) then
          --   return task:success()
          -- end
          return task:running()
        end
      end

      if not blackboard.target then
        return task:fail()
      end

      local from = positionUtils.pixelsToGridCoordinates(blackboard.actor.position.vector)
      local to = positionUtils.pixelsToGridCoordinates(blackboard.target.position.vector)

      if positionUtils.isInPosition(from, to, true) then
        return task:success()
      end

      blackboard.actor:give("path", nil, nil, from.x, from.y, to.x, to.y)
      return task:running()
    end
  })
end
