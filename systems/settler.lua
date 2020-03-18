local Vector = require('libs.brinevector')
local inspect = require('libs.inspect') --luacheck: ignore
local lume = require('libs.lume')
local media = require('utils.media')
local universe = require('models.universe')
local jobManager = require('models.jobManager')
local entityManager = require('models.entityManager')

local settlerSpeed = 200

local SettlerSystem = ECS.System({ pool = { "settler", "worker", "position", "velocity" } })

function SettlerSystem:initializeTestSettlers()
  for _ = 1,20,1 do
    local worldSize = universe.getSize()
    local position
    while true do
      position = universe.clampToWorldBounds(Vector(math.random(worldSize.x), math.random(worldSize.y)))
      if universe.isPositionWalkable(position) then
        break
      end
    end
    local settler = ECS.Entity():assemble(ECS.a.creatures.settler, position)
    self:getWorld():addEntity(settler)
  end
end

return SettlerSystem
