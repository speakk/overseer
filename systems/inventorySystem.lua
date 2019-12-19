local components = require('libs/concord').components

local InventorySystem = ECS.System("inventory", {components.inventory})

function InventorySystem:init()  --luacheck: ignore
end

function InventorySystem:addItemToEntity(entity, item) --luacheck: ignore
  local contents = entity:get(components.inventory).contents
  table.insert(contents,item)
end

function InventorySystem:update(dt) --luacheck: ignore
  -- for _, entity in ipairs(self.pool.objects) do
  -- end
end

return InventorySystem

