local Vector = require('libs/brinevector/brinevector')
local lume = require('libs/lume')
--local inspect = require('libs/inspect')
local commonComponents = require('components/common')
local componentLoader = require('ecsLoaders/componentLoader')
local constructionTypes = require('data/constructionTypes')

local ItemSystem = ECS.System({commonComponents.Item})


-- local function initializeItemsOnGroundTable(size)
--   local array = {}
--   for y = 1,size.y,1 do
--     local row = {}
--     for x = 1,size.x,1 do
--       row[x] = {}
--     end
--     array[y] = row
--   end
--
--   return array
-- end

function ItemSystem:initializeTestItems()
  local mapSize = self.mapSystem:getSize()
  local randomTable = {
    walls = { "wooden_wall", "iron_wall" },
    raw_materials = { "wood", "iron", "stone", "steel" }
  }

  for i=1,200,1 do  --luacheck: ignore
    local item = ECS.Entity()
    local position = Vector(math.random(mapSize.x), math.random(mapSize.y))
    local keys1 = lume.keys(randomTable)
    local key = keys1[math.random(#keys1)]
    local category = randomTable[key]
    local itemName = category[math.random(#category)]
    local selector = key .. "." .. itemName
    local amount = love.math.random(30)
    local item = self:createItem(selector, amount)
    self:placeItemOnGround(item, position)
  end
end

-- function ItemSystem:createItem(selector, amount, gridPosition)
--   amount = amount or 1
-- 
--   local item = ECS.Entity()
--   local itemData = constructionTypes.getBySelector(selector)
--   local color = itemData.color or { 0.5, 0.5, 0.5 }
--   item:give(commonComponents.Item, itemData, selector)
--   :give(commonComponents.Draw, color, Vector(16, 16))
--   :give(commonComponents.Amount, 100)
-- 
--   if gridPosition then
--     self:placeItemOnGround(item, gridPosition)
--   end
-- 
--   item:give(commonComponents.Amount, amount)
-- 
--   item:apply()
--   self:getInstance():addEntity(item)
-- 
--   return item
-- end

function ItemSystem:createItem(selector, amount)
  amount = amount or 1

  local item = ECS.Entity()
  local itemData = constructionTypes.getBySelector(selector)
  local color = itemData.color or { 0.5, 0.5, 0.5 }
  item:give(commonComponents.Item, itemData, selector)
  :give(commonComponents.Draw, color, Vector(16, 16))
  :give(commonComponents.Amount, amount)

  item:apply()
  self:getInstance():addEntity(item)

  return item
end

function ItemSystem:init(mapSystem)  --luacheck: ignore
  self.mapSystem = mapSystem
  self.itemsOnGround = {}
end

function ItemSystem:placeItemOnGround(item, gridPosition) --luacheck: ignore
  local selector = item:get(commonComponents.Item).selector
  if not self.itemsOnGround[selector] then
    self.itemsOnGround[selector] = {}
  end

  item:give(commonComponents.Position, self.mapSystem:gridPositionToPixels(gridPosition))
  item:apply()

  table.insert(self.itemsOnGround[selector], item)
end

function ItemSystem:getItemFromGround(itemSelector, gridPosition) --luacheck: ignore
  local items = self.itemsOnGround[itemSelector]
  for _, item in ipairs(items) do
    local position = item:get(commonComponents.Position).vector
    if gridPosition == self.mapSystem:pixelsToGridCoordinates(position) then
      return item
    end
  end

  return nil -- Could not find item on ground
end

function ItemSystem:getItemsFromGroundBySelector(itemSelector) --luacheck: ignore
  return self.itemsOnGround[itemSelector]
end

function ItemSystem:removeItemFromGround(item)
  if item:has(commonComponents.Position) then
    item:remove(commonComponents.Position)
    item:apply()
  end
  local selector = item:get(commonComponents.Item).selector
  lume.remove(self.itemsOnGround[selector], item)
end

ItemSystem.Inventory = {}

function ItemSystem:getInventoryItemBySelector(inventory, selector)
  local itemEnt = lume.match(inventory, function(itemInInv)
    return itemInInv:get(commonComponents.Item).selector == selector end)
  return itemEnt
end
-- TODO: Add "Amount" parameter, split the item as needed
function ItemSystem:popInventoryItemBySelector(inventory, selector, amount)
  local item = self:getInventoryItemBySelector(inventory, selector)
  if item then
    local currentAmount = item:get(commonComponents.Amount).amount
    local diff = currentAmount - amount
    if diff <= 0 then
      lume.remove(inventory, item)
      return item
    end

    item:give(commonComponents.Amount, diff)
    local itemCopy = self:createItem(selector, amount)
    itemCopy:give(commonComponents.Amount, amount)
    return itemCopy
  end
end

return ItemSystem
