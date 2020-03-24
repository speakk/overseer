local positionUtils = require('models.positionUtils')
local entityManager = require('models.entityManager')

return function(e, gridPosition)
  e
  :give("id", entityManager.generateId())
  :give("position", positionUtils.gridPositionToPixels(gridPosition))
  :give("speed", 300)
  :give("satiety")
  :give("health")
  :give("velocity")
end
