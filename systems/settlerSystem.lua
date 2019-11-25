local cpml = require('cpml')
local commonComponents = require('components/common')

local SettlerSystem = class("SettlerSystem", System)

function SettlerSystem:initialize()
  System.initialize(self)
  self.workQueue = {}
  --EventManager:addListener("blueprint_activated", self, self.blueprintActivated)
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

