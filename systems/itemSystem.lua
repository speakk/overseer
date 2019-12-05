local Vector = require('libs/brinevector/brinevector')
local lume = require('libs/lume')
local inspect = require('libs/inspect')
local commonComponents = require('components/common')
local constructionTypes = require('data/constructionTypes')

local ItemSystem = ECS.System({commonComponents.Item})

local itemsOnGround = {}
local itemPositionsInGridIndexedBySelector = {}

local function initializeItemsOnGroundTable(size)
  local array = {}
  for y = 1,size.y,1 do
    local row = {}
    for x = 1,size.x,1 do
      row[x] = {}
    end
    array[y] = row
  end

  return array
end

function ItemSystem:initializeTestItems()
  local mapSize = self.mapSystem:getSize()
  local randomTable = {
    walls = { "wooden_wall", "iron_wall" },
    raw_materials = { "wood", "iron", "stone" }
  }

  for i=1,40,1 do  --luacheck: ignore
    local item = ECS.Entity()
    local position = Vector(math.random(mapSize.x), math.random(mapSize.y))
    local keys1 = lume.keys(randomTable)
    local key = keys1[math.random(#keys1)]
    local category = randomTable[key]
    local itemName = category[math.random(#category)]
    local selector = key .. "." .. itemName
    local itemData = constructionTypes.getBySelector(selector)
    local color = itemData.color or { 0.5, 0.5, 0.5 }
    item:give(commonComponents.Position, self.mapSystem:gridPositionToPixels(position))
    :give(commonComponents.Selector, selector)
    :give(commonComponents.Item, itemData)
    :give(commonComponents.Draw, color)
    :apply()
    self:getInstance():addEntity(item)
    self:placeItemOnGround(item, position)
  end
end

function ItemSystem:init(mapSystem)  --luacheck: ignore
  self.mapSystem = mapSystem
  itemsOnGround = initializeItemsOnGroundTable(mapSystem:getSize())
end

local function placeSelectorIndexedItem(item, position)
  local selector = item:get(commonComponents.Selector).selector
  if not itemPositionsInGridIndexedBySelector[selector] then
    itemPositionsInGridIndexedBySelector[selector] = {}
  end

  table.insert(itemPositionsInGridIndexedBySelector[selector], position)
end

function ItemSystem:placeItemOnGround(item, gridPosition) --luacheck: ignore
  table.insert(itemsOnGround[gridPosition.y][gridPosition.x], item)
  placeSelectorIndexedItem(item)
end

function ItemSystem:getItemFromGround(itemSelector, gridPosition) --luacheck: ignore
  local itemsInPosition = itemsOnGround[gridPosition.y][gridPosition.x]
  for _, item in ipairs(itemsInPosition) do
    local selector = item:get(commonComponents.Selector).selector
    if itemSelector == selector then
      return item
    end
  end

  return nil -- Could not find item on ground
end

function ItemSystem:getItemPositionsFromGroundBySelector(itemSelector) --luacheck: ignore
  return itemPositionsInGridIndexedBySelector[itemSelector]
end

function ItemSystem:getItemsFromGroundBySelector(itemSelector) --luacheck: ignore
  local items = {}
  for _, position in ipairs(itemPositionsInGridIndexedBySelector[itemSelector]) do
    table.insert(items, itemsOnGround[position.y][position.x])
  end

  return items
end

function ItemSystem:removeItemFromGround(item)
  local position = item:get(commonComponents.Position).vector
  local gridPosition = self.mapSystem:pixelsToGridCoordinates(position)
  local items = itemsOnGround[gridPosition.y][gridPosition.x]
  local potentialItem = lume.match(items, function(it) return it == item end)

  if potentialItem then
    lume.remove(items, potentialItem)
  end
end

function ItemSystem:update(dt) --luacheck: ignore
  -- for _, entity in ipairs(self.pool.objects) do
  -- end
end

return ItemSystem
