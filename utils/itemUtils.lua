local Gamestate = require("libs.hump.gamestate")
local inspect = require('libs.inspect') -- luacheck: ignore
local entityRegistry = require('models.entityRegistry')

local ItemUtils = {}

function ItemUtils.splitItemStackIfNeeded(item, amount)
  if not item then error("Trying to split nil item") end
  local currentAmount = item.amount.amount
  local diff = currentAmount - amount
  if diff <= 0 then
    return item, false
  end

  local selector = item.selector.selector
  item:give("amount", diff)
  local itemCopy = ItemUtils.createItem(selector, amount)
  itemCopy:give("amount", amount)
  return itemCopy, true
end

function ItemUtils.createItem(selector, amount)
  amount = amount or 1

  local item = ECS.Entity():assemble(ECS.a.getBySelector(selector))
  --local color = itemData.color or { 0.5, 0.5, 0.5 }
  item:give("item", itemData)
  :give("selector", selector)
  :give("amount", amount)
  :give("name", "Item: " .. selector)
  :give("id", entityRegistry.generateId())

  local world = Gamestate.current().world

  world:addEntity(item)
  world:__flush()

  return item
end

function ItemUtils.takeItemFromGround(originalItem, amount)
  local selector = originalItem.selector.selector
  local item, wasSplit = ItemUtils.splitItemStackIfNeeded(originalItem, amount)

  if not wasSplit then
    --lume.remove(entityItemSelectorMap[selector], originalItem)
    originalItem:remove("position")
    originalItem:remove("onMap")
  end

  return item
end

return ItemUtils
