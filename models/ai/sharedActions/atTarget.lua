local BehaviourTree = require('libs.behaviourtree')
local positionUtils = require('utils.position')

return function(blackboard)
  return function()
    local gridPosition = positionUtils.pixelsToGridCoordinates(blackboard.actor.position.vector)
    local targetGridPosition = positionUtils.pixelsToGridCoordinates(blackboard.target.position.vector)

    if positionUtils.isInPosition(gridPosition, targetGridPosition, true) then
      return false, true
    else
      return false, false
    end
  end
end
