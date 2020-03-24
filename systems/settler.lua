local Vector = require('libs.brinevector')
local inspect = require('libs.inspect') --luacheck: ignore
local lume = require('libs.lume')
local media = require('utils.media')
local universe = require('models.universe')
local jobManager = require('models.jobManager')
local entityManager = require('models.entityManager')

local settlerSpeed = 200

local SettlerSystem = ECS.System({ pool = { "settler", "worker", "position", "velocity" } })

local frontNames = { "Herbert", "George", "Rebecca", "Suzanne", "Korb", "Lily", "Mark", "Bran", "Mary", "Aloysius", "Marshal" }
local lastNames = { "Mallory", "Rombert", "Bluelie", "Smith", "Knob", "Wallace", "Stratham", "Prism" }

function SettlerSystem:initializeTestSettlers()
  for _ = 1,40 do
    local worldSize = universe.getSize()
    local position
    while true do
      position = universe.clampToWorldBounds(Vector(math.random(worldSize.x), math.random(worldSize.y)))
      if universe.isPositionWalkable(position) then
        break
      end
    end
    local settler = ECS.Entity():assemble(ECS.a.creatures.settler, position, lume.randomchoice(frontNames) .. " " .. lume.randomchoice(lastNames))
    self:getWorld():addEntity(settler)
  end
end

function SettlerSystem:initializeTestCreatures()
  for _ = 1,20 do
    local worldSize = universe.getSize()
    local position
    while true do
      position = universe.clampToWorldBounds(Vector(math.random(worldSize.x), math.random(worldSize.y)))
      if universe.isPositionWalkable(position) then
        break
      end
    end
    local creature = ECS.Entity():assemble(ECS.a.creatures.crawler, position)
    self:getWorld():addEntity(creature)
  end
end

return SettlerSystem
