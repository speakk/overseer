local universe = require('models.universe')
local entityManager = require('models.entityManager')

return function(e, gridPosition)
  e
  :give("id", entityManager.generateId())
  :give("position", universe.gridPositionToPixels(gridPosition))
  :give("speed", 300)
  :give("satiety")
  :give("health")
  :give("velocity")
end
