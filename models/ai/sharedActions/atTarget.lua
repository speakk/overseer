local BehaviourTree = require('libs.behaviourtree')
local positionUtils = require('utils.position')

return function()
  return BehaviourTree.Task:new({
    run = function(task, blackboard)
      local gridPosition = positionUtils.pixelsToGridCoordinates(blackboard.actor.position.vector)
      local targetGridPosition = positionUtils.pixelsToGridCoordinates(blackboard.target.position.vector)

      if positionUtils.isInPosition(gridPosition, targetGridPosition, true) then
        task:success()
      else
        task:fail()
      end
    end
  })
end
