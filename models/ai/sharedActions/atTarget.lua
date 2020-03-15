local BehaviourTree = require('libs.behaviourtree')
local universe = require('models.universe')

return function()
  return BehaviourTree.Task:new({
  run = function(task, blackboard)
    print("atTarget")
    local gridPosition = universe.pixelsToGridCoordinates(blackboard.actor.position.vector)
    local targetGridPosition = universe.pixelsToGridCoordinates(blackboard.target.position.vector)

    if universe.isInPosition(gridPosition, targetGridPosition, true) then
      task:success()
    else
      task:fail()
    end
  end
  })
end
