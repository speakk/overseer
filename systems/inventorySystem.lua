local commonComponents = require('components/common')

local InventorySystem = ECS.System({commonComponents.inventory})

function InventorySystem:init()  --luacheck: ignore
end

function InventorySystem:update(dt) --luacheck: ignore
  -- for _, entity in ipairs(self.pool.objects) do
  -- end
end

return InventorySystem

