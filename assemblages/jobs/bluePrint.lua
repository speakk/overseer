local positionUtils = require('utils.position')
local itemUtils = require('utils.itemUtils')
local entityRegistry = require('models.entityRegistry')

return function(e, gridPosition)
  e
  :give("job", "bluePrint", "bluePrintFinished")
  :give("id", entityRegistry.generateId())
  :give("onMap")
  :give("bluePrintJob", 1)
  :give("inventory") -- Item consumed so far
  :give("position", positionUtils.gridPositionToPixels(gridPosition))
end
