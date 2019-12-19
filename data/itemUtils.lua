local lume = require('libs/lume')

local ItemUtils = {}

local itemsOnGround = {}

-- local world
-- 
-- function ItemUtils.init(newWorld)
--   world = newWorld
-- end

function ItemUtils.getInventoryItemBySelector(inventory, selector) -- luacheck: ignore
  local itemEnt = lume.match(inventory, function(itemInInv)
    return itemInInv:get(components.item).selector == selector end)
  return itemEnt
end

-- Return item, wasSplit
function ItemUtils:splitItemStackIfNeeded(item, amount)
  if not item then error("Trying to split nil item") end
  local currentAmount = item:get(components.amount).amount
  local diff = currentAmount - amount
  if diff <= 0 then
    return item, false
  end

  local selector = item:get(components.item).selector
  item:give(components.amount, diff)
  local itemCopy = ItemUtils.createItem(selector, amount)
  itemCopy:give(components.amount, amount)
  return itemCopy, true
end

function ItemUtils.createItem(selector, amount)
  amount = amount or 1

  local item = ECS.Entity()
  local itemData = constructionTypes.getBySelector(selector)
  local color = itemData.color or { 0.5, 0.5, 0.5 }
  item:give(components.item, itemData, selector)
  :give(components.sprite, itemData.sprite)
  :give(components.amount, amount)

  item:apply()
  --world:addEntity(item)

  return item
end

function ItemUtils.placeItemOnGround(item, gridPosition) --luacheck: ignore
  local selector = item:get(components.item).selector
  if not itemsOnGround[selector] then
    itemsOnGround[selector] = {}
  end

  item:give(components.position, gridUtils.gridPositionToPixels(gridPosition))
  item:apply()

  table.insert(itemsOnGround[selector], item)
end

function ItemUtils.getItemFromGround(itemSelector, gridPosition) --luacheck: ignore
  local items = itemsOnGround[itemSelector]
  for _, item in ipairs(items) do
    local position = item:get(components.position).vector
    if gridPosition == gridUtils:pixelsToGridCoordinates(position) then
      return item
    end
  end

  return nil -- Could not find item on ground
end

function ItemUtils.getItemsFromGroundBySelector(itemSelector) --luacheck: ignore
  return itemsOnGround[itemSelector]
end

function ItemUtils.takeItemFromGround(originalItem, amount)
  local selector = originalItem:get(components.item).selector
  local item, wasSplit = splitItemStackIfNeeded(originalItem, amount)

  if not wasSplit then
    lume.remove(itemsOnGround[selector], originalItem)
    if originalItem:has(components.position) then
      originalItem:remove(components.position)
      originalItem:apply()
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
