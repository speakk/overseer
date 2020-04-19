local entityRegistry = require('models.entityRegistry')

local DestructSystem = ECS.System()

local function recursiveDelete(self, entity)
  if entity.children then
    for _, childId in ipairs(entity.children.children) do
      local child = entityRegistry.get(childId)
      recursiveDelete(self, child)
    end
  end

  if entity.inventory then
    local inventory = entity.inventory

    for _, itemId in ipairs(inventory.inventory) do
      print("itemId", itemId)
      local item = entityRegistry.get(itemId)
      print("item", item)
      item:give("onMap")
      -- TODO: If no space then randomize nearby position
      --local itemPosition = currentGridPosition
      item:give("position", entity.position.vector.copy)
    end
  end

  self:getWorld():removeEntity(entity)
end

function DestructSystem:destructEntities(entities)
  for _, entity in ipairs(entities) do
    if not entity.creature then
      if not entity.bluePrint then
        if not entity.job or not entity.job.jobType == "destruct" then
          -- TODO: Using immediateDestroy here, but really should do destructFinished
          entity:give("job", "destruct", "immediateDestroy")
        end
      else
        recursiveDelete(self, entity)
      end
    end
  end
end

function DestructSystem:immediateDestroy(entity)
  recursiveDelete(self, entity)
end

local destructSpeedModifier = 5
function DestructSystem:destructProgress(health, amount) -- luacheck: ignore
  health.value = health.value - amount * destructSpeedModifier
  print("health / durability now", health.value)
end

return DestructSystem
