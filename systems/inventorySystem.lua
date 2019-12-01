local commonComponents = require('components/common')

local InventorySystem = ECS.System({commonComponents.inventory})

function InventorySystem:init()
end

function InventorySystem:update(dt)
  -- for _, entity in ipairs(self.pool.objects) do
  -- end
end

return InventorySystem

