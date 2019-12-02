local commonComponents = require('components/common')

local InventorySystem = ECS.System({commonComponents.Inventory})

function InventorySystem:init()  --luacheck: ignore
end

function InventorySystem:addItemToEntity(entity, item)
  local contents = entity:get(commonComponents.Inventory).contents
  table.insert(contents,item)
end

function InventorySystem:update(dt) --luacheck: ignore
  -- for _, entity in ipairs(self.pool.objects) do
  -- end
end

return InventorySystem

