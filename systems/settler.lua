local Vector = require('libs.brinevector')
local inspect = require('libs.inspect') --luacheck: ignore
local lume = require('libs.lume')
local positionUtils = require('models.positionUtils')

local SettlerSystem = ECS.System({ pool = { "settler", "worker", "position", "velocity" } })

local frontNames = { "Herbert", "George", "Rebecca", "Suzanne", "Korb",
"Lily", "Mark", "Bran", "Mary", "Aloysius", "Marshal" }
local lastNames = { "Mallory", "Rombert", "Bluelie", "Smith", "Knob", "Wallace", "Stratham", "Prism" }

function SettlerSystem:initializeTestSettlers()
  for _ = 1,40 do
    local worldSize = positionUtils.getSize()
    local position
    while true do
      position = positionUtils.clampToWorldBounds(Vector(math.random(worldSize.x), math.random(worldSize.y)))
      if positionUtils.isPositionWalkable(position) then
        break
      end
    end
    local settler = ECS.Entity():assemble(ECS.a.creatures.settler,
    position,
    lume.randomchoice(frontNames) .. " " .. lume.randomchoice(lastNames)
    )
    self:getWorld():addEntity(settler)
  end
end

function SettlerSystem:initializeTestCreatures()
  for _ = 1,20 do
    local worldSize = positionUtils.getSize()
    local position
    while true do
      position = positionUtils.clampToWorldBounds(Vector(math.random(worldSize.x), math.random(worldSize.y)))
      if positionUtils.isPositionWalkable(position) then
        break
      end
    end
    local creature = ECS.Entity():assemble(ECS.a.creatures.crawler, position)
    self:getWorld():addEntity(creature)
  end
end

return SettlerSystem
