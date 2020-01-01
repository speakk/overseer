local lume = require('libs.lume')
local inspect = require('libs.inspect') -- luacheck: ignore
local universe = require('models.universe')
local entityReferenceManager = require('models.entityReferenceManager')
local constructionTypes = require('data.constructionTypes')

local ItemUtils = {}

local itemsOnGround = {}

-- local world
--
-- function ItemUtils.init(newWorld)
--   world = newWorld
-- end

function ItemUtils.getInventoryItemBySelector(inventory, selector) -- luacheck: ignore
  local itemEnt = lume.match(inventory, function(itemInInv)
    return itemInInv:get(ECS.Components.item).selector == selector end)
  return itemEnt
end

-- Return item, wasSplit
function ItemUtils.splitItemStackIfNeeded(item, amount)
  if not item then error("Trying to split nil item") end
  local currentAmount = item:get(ECS.Components.amount).amount
  local diff = currentAmount - amount
  if diff <= 0 then
    return item, false
  end

  local selector = item:get(ECS.Components.item).selector
  item:give(ECS.Components.amount, diff)
  local itemCopy = ItemUtils.createItem(selector, amount)
  itemCopy:give(ECS.Components.amount, amount)
  return itemCopy, true
end

function ItemUtils.createItem(selector, amount)
  amount = amount or 1

  local item = ECS.Entity()
  local itemData = constructionTypes.getBySelector(selector)
  --local color = itemData.color or { 0.5, 0.5, 0.5 }
  item:give(ECS.Components.item, itemData, selector)
  :give(ECS.Components.sprite, itemData.sprite)
  :give(ECS.Components.amount, amount)
  :give(ECS.Components.serialize)
  :give(ECS.Components.id, entityReferenceManager.generateId())

  --world:addEntity(item)

  return item
end

function ItemUtils.placeItemOnGround(item, gridPosition) --luacheck: ignore
  local selector = item:get(ECS.Components.item).selector
  if not itemsOnGround[selector] then
    itemsOnGround[selector] = {}
  end

  item:give(ECS.Components.position, universe.gridPositionToPixels(gridPosition))
  table.insert(itemsOnGround[selector], item)
end

function ItemUtils.getItemFromGround(itemSelector, gridPosition) --luacheck: ignore
  local items = itemsOnGround[itemSelector]
  for _, item in ipairs(items) do
    local position = item:get(ECS.Components.position).vector
    if gridPosition == universe.pixelsToGridCoordinates(position) then
      return item
    end
  end

  return nil -- Could not find item on ground
end

function ItemUtils.getItemsFromGroundBySelector(itemSelector) --luacheck: ignore
  return itemsOnGround[itemSelector]
end

function ItemUtils.takeItemFromGround(originalItem, amount)
  local selector = originalItem:get(ECS.Components.item).selector
  local item, wasSplit = ItemUtils.splitItemStackIfNeeded(originalItem, amount)

  if not wasSplit then
    lume.remove(itemsOnGround[selector], originalItem)
    if originalItem:has(ECS.Components.position) then
      originalItem:remove(ECS.Components.position)
    end
  end

  return item
end

function ItemUtils.popInventoryItemBySelector(inventory, selector, amount)
  local originalItem = ItemUtils.getInventoryItemBySelector(inventory, selector)
  print("Getting selection", selector, originalItem)
  if not originalItem then return end
  local item, wasSplit = ItemUtils.splitItemStackIfNeeded(originalItem, amount)
  if not wasSplit then
    lume.remove(inventory, item)
  end

  return item
end


return ItemUtils
