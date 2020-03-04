local lume = require 'libs.lume'
local entityManager = require 'models.entityManager'
local ItemUtils = require 'utils.itemUtils'
-- TODO: Add the methods into a metatable
local inventory = ECS.Component(function(component, inventory)
  component.inventory = inventory or {}

  component.findItem = function(e, selector) -- luacheck: ignore
    local itemId = lume.match(component.inventory, function(itemId)
      local item = entityManager.get(itemId)
      return item:get(ECS.c.selector).selector == selector
    end)
    return itemId
  end

  component.popItem = function(e, selector, amount)
    local originalItemId = e:findItem(selector)
    if not originalItemId then return end
    local item, wasSplit = ItemUtils.splitItemStackIfNeeded(entityManager.get(originalItemId), amount)
    if not wasSplit then
      lume.remove(component.inventory, item:get(ECS.c.id).id)
    end

    return item
  end

  component.insertItem = function(e, itemId)
    print("Inserting id into inventory", itemId)
    local item = entityManager.get(itemId)
    local amount = item:get(ECS.c.amount).amount
    local selector = item:get(ECS.c.selector).selector

    local existingId = lume.match(component.inventory, function(invItemId)
      local invItem = entityManager.get(invItemId)
      return invItem:get(ECS.c.selector).selector == selector
    end)

    if existingId then
      local existing = entityManager.get(existingId)
      local existingAmount = existing:get(ECS.c.amount).amount
      existingAmount = existingAmount + amount
      existing:get(ECS.c.amount).amount = existingAmount
    else
      --entityManager.registerReference(item:get(ECS.c.id).id, function(deletedId) e.inventory[deletedId] = nil end)
      table.insert(component.inventory, itemId)
    end
  end
end)

function inventory:serialize()
  local inv = {}
  for _, entityId in ipairs(self.inventory) do
    table.insert(inv, entityId)
  end
  return { inventoryIds = inv }
end

function inventory:deserialize(data)
  self.inventory = {}
  for _, entityId in ipairs(data.inventoryIds) do
    table.insert(self.inventory, entityId)
  end
end
return inventory
