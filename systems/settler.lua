local Vector = require('libs.brinevector')
local Gamestate = require("libs.hump.gamestate")
local inspect = require('libs.inspect') --luacheck: ignore
local lume = require('libs.lume')
local positionUtils = require('utils.position')

local SettlerSystem = ECS.System({ pool = { "settler", "worker", "position", "velocity" } })

local frontNames = { "Herbert", "George", "Rebecca", "Suzanne", "Korb",
"Lily", "Mark", "Bran", "Mary", "Aloysius", "Marshal" }
local lastNames = { "Mallory", "Rombert", "Bluelie", "Smith", "Knob", "Wallace", "Stratham", "Prism" }

function SettlerSystem:initializeTestSettlers()
  for _ = 1,20 do
    local mapConfig = Gamestate.current().mapConfig
    local position
    while true do
      position = positionUtils.clampToWorldBounds(Vector(math.random(mapConfig.width), math.random(mapConfig.height)))
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
    local mapConfig = Gamestate.current().mapConfig
    local position
    while true do
      position = positionUtils.clampToWorldBounds(Vector(math.random(mapConfig.width), math.random(mapConfig.height)))
      if positionUtils.isPositionWalkable(position) then
        break
      end
    end
    local creature = ECS.Entity():assemble(ECS.a.creatures.crawler, position)
    self:getWorld():addEntity(creature)
  end
end

return SettlerSystem
