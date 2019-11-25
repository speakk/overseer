local cpml = require('libs/cpml')
local commonComponents = require('components/common')

local SettlerSystem = class("SettlerSystem", System)

BluePrintActivated = class("BluePrintActivated")

function BluePrintActivated:initialize(entity)
    -- self.key = key
    -- self.isrepeat = isrepeat
end

function SettlerSystem:initialize(eventManager)
  self.eventManager = eventManager
  System.initialize(self)
  self.workQueue = {}
  eventManager:addListener("blueprint_activated", self, self.blueprintActivated)
end

-- Define this System requirements.
function SettlerSystem:requires()
  return {"settler", "position", "velocity"}
end

function SettlerSystem:update(dt)
  for _, entity in pairs(self.targets) do
    local velocity = entity:get("velocity")
    velocity.vector = cpml.vec2(math.random(300)-150, math.random(300)-150)
    velocity.vector:normalize()
  end
end

function SettlerSystem.blueprintActivated(table, event)
  print("Activated", table, event)
end

return SettlerSystem

