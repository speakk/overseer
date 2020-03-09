local BehaviourTree = require('libs.behaviourtree')
local universe = require('models.universe')

return function()
  return BehaviourTree.Task:new({
    run = function(task, blackboard)
      --print("Goto")
      if blackboard.actor:has(ECS.c.path) then
        if blackboard.actor:get(ECS.c.path).finished then
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

      local from = universe.pixelsToGridCoordinates(blackboard.actor:get(ECS.c.position).vector)
      local to = universe.pixelsToGridCoordinates(blackboard.target:get(ECS.c.position).vector)
      blackboard.actor:give(ECS.c.path, nil, nil, from.x, from.y, to.x, to.y)
      task:running()
    end
  })
end
