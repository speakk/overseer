local InventorySystem = ECS.System("inventory", {ECS.Components.inventory})

function InventorySystem:init()  --luacheck: ignore
end

function InventorySystem:addItemToEntity(entity, item) --luacheck: ignore
  local contents = entity:get(ECS.Components.inventory).contents
  table.insert(contents,item)
end

function InventorySystem:update(dt) --luacheck: ignore
  -- for _, entity in ipairs(self.pool) do
  -- end
end

return InventorySystem

