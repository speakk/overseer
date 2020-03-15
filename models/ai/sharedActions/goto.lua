local BehaviourTree = require('libs.behaviourtree')
local universe = require('models.universe')

return function()
  return BehaviourTree.Task:new({
    run = function(task, blackboard)
      print("Goto")
      if blackboard.actor.path then
        if blackboard.actor.path.finished then
          blackboard.actor:remove(ECS.c.path)
          task:success()
          return
        else
          task:running()
          return
        end
      end

      if not blackboard.target then
        task:fail()
        return
      end

      local from = universe.pixelsToGridCoordinates(blackboard.actor.position.vector)
      local to = universe.pixelsToGridCoordinates(blackboard.target.position.vector)
      blackboard.actor:give(ECS.c.path, nil, nil, from.x, from.y, to.x, to.y)
      task:running()
    end
  })
end
