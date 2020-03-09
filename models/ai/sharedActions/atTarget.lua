local BehaviourTree = require('libs.behaviourtree')
local universe = require('models.universe')

return function()
  return BehaviourTree.Task:new({
  run = function(task, blackboard)
    --print("atTarget")
    local gridPosition = universe.pixelsToGridCoordinates(blackboard.actor:get(ECS.c.position).vector)
    local targetGridPosition = universe.pixelsToGridCoordinates(blackboard.target:get(ECS.c.position).vector)

    if universe.isInPosition(gridPosition, targetGridPosition, true) then
      task:success()
    else
      task:fail()
    end
  end
  })
end
