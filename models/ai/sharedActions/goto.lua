local positionUtils = require('utils.position')

return function(blackboard)
  return function()
    print("GOTO")
    if blackboard.actor.path then
      if blackboard.actor.path.finished then
        blackboard.actor:remove("path")
        return false, true
      else
        -- if positionUtils.isInPosition(from, to, true) then
        --   return task:success()
        -- end
        return true
      end
    end

    if not blackboard.target then
      return false, false
    end

    local from = positionUtils.pixelsToGridCoordinates(blackboard.actor.position.vector)
    local to = positionUtils.pixelsToGridCoordinates(blackboard.target.position.vector)

    if positionUtils.isInPosition(from, to, true) then
      return false, true
    end

    blackboard.actor:give("path", nil, nil, from.x, from.y, to.x, to.y)
    return true
  end
end
