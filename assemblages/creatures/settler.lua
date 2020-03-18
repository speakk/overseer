local Vector = require('libs.brinevector')
local inspect = require('libs.inspect') --luacheck: ignore
local lume = require('libs.lume')
local media = require('utils.media')
local universe = require('models.universe')
local jobManager = require('models.jobManager')
local entityManager = require('models.entityManager')

return function(settler, gridPosition)
  local worldSize = universe.getSize()

  settler:give("position", universe.gridPositionToPixels(gridPosition))
  :give("sprite", 'characters.settler1_01')
  :give("id", entityManager.generateId())
  :give("settler")
  :give("ai", 'settler')
  :give("speed", 300)
  :give("name", "Settler")
  :give("inventory")
  :give("worker")
  :give("velocity")
  :give("animation", {
    walk = {
      targetComponent = 'sprite',
      targetProperty = 'selector',
      interpolate = false,
      repeatAnimation = true,
      values = {
        "characters.settler1_01", "characters.settler1_02", "characters.settler1_03"
      },
      currentValueIndex = 1,
      frameLength = 0.2, -- in ms
      lastFrameUpdate = love.timer.getTime(),
      finished = false
    }
  },
  {
    'walk'
  })

end
