local Gamestate = require("libs.hump.gamestate")
local lume = require('libs.lume')
local inspect = require('libs.inspect') --luacheck: ignore
local itemUtils = require('utils.itemUtils')
local positionUtils = require('utils.position')

local entityFinder = {}

local entityPosMap = {}
local entityItemSelectorMap = {}

function entityFinder.onOnMapItemAdded(_, entity)
  local selector = entity.selector.selector
  if not entityItemSelectorMap[selector] then
    entityItemSelectorMap[selector] = {}
  end

  table.insert(entityItemSelectorMap[selector], entity)
end

function entityFinder.onOnMapItemRemoved(_, entity)
  local selector = entity.selector.selector

  local items = entityItemSelectorMap[selector]
  if items then
    lume.remove(items, entity)
  end
end

function entityFinder.getPositionStringFromEntity(entity)
  local pixelPosition = entity.position.vector
  local position = positionUtils.pixelsToGridCoordinates(pixelPosition)
  return entityFinder.getGridPositionString(position)
end

function entityFinder.getGridPositionString(gridPosition)
  return gridPosition.x .. ":" .. gridPosition.y
end

function entityFinder.onOnMapEntityAdded(_, entity)
  local posString = entityFinder.getPositionStringFromEntity(entity)
  if not entityPosMap[posString] then
    entityPosMap[posString] = {}
  end

  table.insert(entityPosMap[posString], entity)
end

function entityFinder.onOnMapEntityRemoved(_, entity)
  if not entity.position then return end
  local posString = entityFinder.getPositionStringFromEntity(entity)

  if not entityPosMap[posString] then
    error("Trying to remove nonExistent entity from pos: " .. posString)
  end

  lume.remove(entityPosMap[posString], entity)
end

function entityFinder.getEntitiesInLocation(gridPosition)
  local posString = gridPosition.x .. ":" .. gridPosition.y

  if not entityPosMap[posString] then
    return {}
  end

  return entityPosMap[posString]
end

function entityFinder.isPositionOccupied(gridPosition)
  return entityPosMap[entityFinder.getGridPositionString(gridPosition)]
end

-- -- TODO: THREADING FUCKS THIS UP
-- function entityFinder.findPathToClosestEmptyCell(gridPosition)
--   print("WELL DUH findPathToClosestEmptyCell")
--   local node = grid:getNodeAt(gridPosition.x, gridPosition.y)
-- 
--   if not entityFinder.isPositionWalkable(gridPosition) then
--     local radius = 1
--     while radius < 10 do
--       for nodeAround in grid:around(node, radius) do
--         if entityFinder.isPositionWalkable(Vector(nodeAround:getX(), nodeAround:getY())) then
--           return entityFinder.getPath(gridPosition, Vector(node:getX(), node:getY()))
--         end
--       end
-- 
--       radius = radius +1
--     end
--   end
-- end

function entityFinder.getEntitiesInCoordinates(coordinateList, selector, componentRequirements)
  local entities = {}

  for _, coordinate in ipairs(coordinateList) do
    local locationEntities = entityFinder.getEntitiesInLocation(coordinate)
    entities = lume.concat(entities, lume.filter(locationEntities, function(entity)
      if selector then
        if not entity.selector or entity.selector.selector ~= selector then
          return false
        end
      end

      if componentRequirements then
        for _, requirement in ipairs(componentRequirements) do
          if not entity[requirement] then return false end
        end
      end

      return true
    end))
  end

  return entities
end

function entityFinder.getItemsOnGround(selector, componentRequirements)
  if componentRequirements then
    if not entityItemSelectorMap[selector] then
      return
    end

    return lume.filter(entityItemSelectorMap[selector], function(entity)
      for _, requirement in ipairs(componentRequirements) do
        if not entity[requirement] then return false end
      end

      return true
    end)
  else
    return entityItemSelectorMap[selector]
  end
end

function entityFinder.getItemFromGround(itemSelector, gridPosition, componentRequirements) --luacheck: ignore
  local items = entityFinder.getItemsOnGround(itemSelector, componentRequirements)
  print("Any items anywhere?", itemSelector, items, #items)
  if not items then return nil end

  for _, item in ipairs(items) do
    local position = positionUtils.pixelsToGridCoordinates(item.position.vector)
    --print("Position", inspect(position))
    if positionUtils.isInPosition(gridPosition, position, true) then
      return item
    end
  end

  return nil -- Could not find item on ground
end

function entityFinder.takeItemFromGround(originalItem, amount)
  local selector = originalItem.selector.selector
  local item, wasSplit = itemUtils.splitItemStackIfNeeded(originalItem, amount)

  if not wasSplit then
    lume.remove(entityItemSelectorMap[selector], originalItem)
    originalItem:remove("position")
    originalItem:remove("onMap")
  end

  return item
end

return entityFinder
