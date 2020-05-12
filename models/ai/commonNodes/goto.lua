local positionUtils = require('utils.position')

return function(actor, blackboard)
  return function()
    print("GOTO")
    if actor.path then
      if actor.path.finished then
        actor:remove("path")
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

    local from = positionUtils.pixelsToGridCoordinates(actor.position.vector)
    local to = positionUtils.pixelsToGridCoordinates(blackboard.target.position.vector)

    if positionUtils.isInPosition(from, to, true) then
      return false, true
    end

    --print("Giving path??", actor, from.x, from.y, from.y, to.x, to.y)
    actor:give("path", nil, nil, from.x, from.y, to.x, to.y)
    return true
  end
end
