local Gamestate = require("libs.hump.gamestate")
local inspect = require('libs.inspect') -- luacheck: ignore
local entityManager = require('models.entityManager')
local constructionTypes = require('data.constructionTypes')

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

  local item = ECS.Entity()
  local itemData = constructionTypes.getBySelector(selector)
  --local color = itemData.color or { 0.5, 0.5, 0.5 }
  item:give("item", itemData)
  :give("selector", selector)
  :give("amount", amount)
  :give("name", "Item: " .. selector)
  :give("id", entityManager.generateId())

  for _, component in ipairs(itemData.components) do
    item:give(component.name, unpack(component.properties))
  end

  local world = Gamestate.current().world

  world:addEntity(item)
  world:__flush()

  return item
end

return ItemUtils
