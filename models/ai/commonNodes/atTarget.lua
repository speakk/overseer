local positionUtils = require('utils.position')

return function(actor, blackboard)
  return function()
    print("AtTarget")
    local gridPosition = positionUtils.pixelsToGridCoordinates(actor.position.vector)
    local targetGridPosition = positionUtils.pixelsToGridCoordinates(blackboard.target.position.vector)

    if positionUtils.isInPosition(gridPosition, targetGridPosition, true) then
      return false, true
    else
      return false, false
    end
  end
end
