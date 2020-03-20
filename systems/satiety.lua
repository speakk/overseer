local Vector = require('libs.brinevector')
-- Create a System class as lovetoys.System subclass.
local SatietySystem = ECS.System({ pool = { "satiety" } })

local hungerSpeed = 10
local maxSatiety = 100

function SatietySystem:update(dt)
  for _, entity in ipairs(self.pool) do
    local satiety = entity.satiety
    satiety.value = satiety.value - hungerSpeed * dt
    if satiety.value <= 0 then
      self:getWorld():emit("satietyAtZero", entity, dt)
    end
  end
end

return SatietySystem

