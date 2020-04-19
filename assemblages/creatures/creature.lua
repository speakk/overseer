local positionUtils = require('utils.position')
local entityRegistry = require('models.entityRegistry')

return function(e, gridPosition)
  e
  :give("id", entityRegistry.generateId())
  :give("position", positionUtils.gridPositionToPixels(gridPosition))
  :give("speed", 300)
  :give("satiety")
  :give("creature")
  :give("health")
  :give("velocity")
end
