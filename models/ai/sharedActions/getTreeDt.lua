local BehaviourTree = require('libs.behaviourtree')

return function()
  return BehaviourTree.Task:new({
    run = function(task, blackboard)
      if not blackboard.lastTick then
        blackboard.lastTick = 0
      end

      local time = love.timer.getTime()
      blackboard.treeDt = time - blackboard.lastTick
      blackboard.lastTick = time
      task:success()
    end
  })
end

