local Gamestate = require("libs.hump.gamestate")
local lume = require('libs.lume')
local inspect = require('libs.inspect') --luacheck: ignore
local itemUtils = require('utils.itemUtils')
local positionUtils = require('utils.position')

local entityFinder = {}

entityFinder.makeIndexFunction = function(key, indexKeyFunction)
  return function(entity, remove)
    local indexes = indexKeyFunction(entity)
    if not type(indexes) == 'table' then
      indexes = { indexes }
    end

    for _, index in ipairs(indexes) do
      if remove then
        local items = entityFinder.indices[key].items[index]
        table.remove_value(items, entity)
      else
        local items = entityFinder.indices[key].items[index] or {}
        table.insert(items, entity)
        entityFinder.indices[key].items[index] = items
      end
    end
  end
end

entityFinder.indices = {
  position = {
    indexFunction = entityFinder.makeIndexFunction("position", entityFinder.getPositionStringFromEntity),
    components = { "position" },
    items = {}
  },
  selector = {
    indexFunction = entityFinder.makeIndexFunction("selector", function(entity)
      local selectorParts = lume.split(entity.selector.selector, '.')
      local indices = {}
      local selectorSoFar = ""
      for _, part in ipairs(selectorParts) do
        selectorSoFar = selectorSoFar + part
        table.insert(indices, selectorSoFar)
        selectorSoFar = selectorSoFar + "."
      end
      return indices
    end),
    components = { "selector" },
    items = {}
  }
}

entityFinder.queryBuilders = {
  positionListAndSelector = function(coords, selector)
    return {
      operation = "intersection",
      items = {
        {
          operation = "union",
          items = functional.map(coords, function(coord)
            return {
              indexKey = "position",
              value = entityFinder.getGridPositionString(coord)
            }
          end)
        },
        {
          operation = "union",
          items = {
            {
              indexKey = "selector",
              value = params.selector
            }
          }
        }
      }
    }
  end,
  positionListAndSelector = function(coords, selector)
    return {
      operation = "intersection",
      items = {
        {
          operation = "union",
          items = functional.map(coords, function(coord)
            return {
              indexKey = "position",
              value = entityFinder.getGridPositionString(coord)
            }
          end)
        },
        {
          operation = "union",
          items = {
            {
              indexKey = "selector",
              value = params.selector
            }
          }
        }
      }
    }
  end,
  positionList = function(coords)
    return {
      operation = "union",
      items = functional.map(coords, function(coord)
        return {
          indexKey = "position",
          value = entityFinder.getGridPositionString(coord)
        }
      end)
    }
  end
}

function entityFinder.getEntities(indexKey, index, componentsFilter)
  local items = entityFinder.indices[indexKey].items[index]

  if componentsFilter then
    items = entityFinder.filterByComponentList(items, componentsFilter)
  end

  return items
end

function entityFinder.filterByComponentList(entities, componentsList)
  return functional.filter(items, function(entity)
    for _, filter in componentsList do
      if not entity[filter] then return false end
    end
    return true
  end)
end

function entityFinder.getEntitiesByMultiplePredicates(predicates, componentsFilter)
  local itemsLists = functional.map(predicates, function(predicate)
    return entityFinder.indices[predicate.indexKey].items[predicate.index]
  end)

  local result = {}

  for i, listA in ipairs(itemsLists) do
    for k in i+1,#itemsLists-i do
      local listB = itemsLists[k]
      table.append_inplace(result, tableUtils.intersection(listA, listB))
    end
  end

  return result
end

local function makeOperation(operationFunction)
  return function(itemsLists)
    local result = {unpack(itemsLists[1])}
    for i in 2,#itemsLists do
      local list = itemsLists[i]
      table.append_inplace(result, operationFunction(result, list))
    end
    return result
  end
end

local operations = {
  intersection = makeOperation(tableUtils.intersection),
  union = makeOperation(function(a, b) return b end)
}

local function doQuery(queryObject)
  if queryObject.operation then
    local operation = queryObject.operation
    return operations(operation)(doQuery(queryObject.items))
  else
    return queryObject
  end
end

function entityFinder.getByQueryObject(queryObject, componentsFilter)
  local result = doQuery(queryObject)
  if componentsFilter then
    result = entityFinder.filterByComponentList(result, componentsFilter)
  end

  return result
end

function entityFinder.getPositionStringFromEntity(entity)
  local pixelPosition = entity.position.vector
  local position = positionUtils.pixelsToGridCoordinates(pixelPosition)
  return entityFinder.getGridPositionString(position)
end

function entityFinder.getGridPositionString(gridPosition)
  return gridPosition.x .. ":" .. gridPosition.y
end


-- local entityPosMap = {}
-- local entityItemSelectorMap = {}

-- function entityFinder.onOnMapItemAdded(_, entity)
--   local selector = entity.selector.selector
--   if not entityItemSelectorMap[selector] then
--     entityItemSelectorMap[selector] = {}
--   end
-- 
--   table.insert(entityItemSelectorMap[selector], entity)
-- end
-- 
-- function entityFinder.onOnMapItemRemoved(_, entity)
--   local selector = entity.selector.selector
-- 
--   local items = entityItemSelectorMap[selector]
--   if items then
--     lume.remove(items, entity)
--   end
-- end
-- 
-- function entityFinder.onOnMapEntityAdded(_, entity)
--   local posString = entityFinder.getPositionStringFromEntity(entity)
--   if not entityPosMap[posString] then
--     entityPosMap[posString] = {}
--   end
-- 
--   table.insert(entityPosMap[posString], entity)
-- end
-- 
-- function entityFinder.onOnMapEntityRemoved(_, entity)
--   if not entity.position then return end
--   local posString = entityFinder.getPositionStringFromEntity(entity)
-- 
--   if not entityPosMap[posString] then
--     error("Trying to remove nonExistent entity from pos: " .. posString)
--   end
-- 
--   lume.remove(entityPosMap[posString], entity)
-- end
-- 
-- function entityFinder.getEntitiesInLocation(gridPosition)
--   local posString = gridPosition.x .. ":" .. gridPosition.y
-- 
--   if not entityPosMap[posString] then
--     return {}
--   end
-- 
--   return entityPosMap[posString]
-- end

function entityFinder.isPositionOccupied(gridPosition)
  return entityFinder.indices.position[entityFinder.getGridPositionString(gridPosition)]
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

-- function entityFinder.getEntitiesInCoordinates(coordinateList, selector, componentRequirements)
--   local entities = {}
-- 
--   for _, coordinate in ipairs(coordinateList) do
--     local locationEntities = entityFinder.getEntitiesInLocation(coordinate)
--     entities = lume.concat(entities, lume.filter(locationEntities, function(entity)
--       if selector then
--         if not entity.selector or entity.selector.selector ~= selector then
--           return false
--         end
--       end
-- 
--       if componentRequirements then
--         for _, requirement in ipairs(componentRequirements) do
--           if not entity[requirement] then return false end
--         end
--       end
-- 
--       return true
--     end))
--   end
-- 
--   return entities
-- end

-- function entityFinder.getItemsOnGround(selector, componentRequirements)
--   if componentRequirements then
--     if not entityItemSelectorMap[selector] then
--       return
--     end
-- 
--     return lume.filter(entityItemSelectorMap[selector], function(entity)
--       for _, requirement in ipairs(componentRequirements) do
--         if not entity[requirement] then return false end
--       end
-- 
--       return true
--     end)
--   else
--     return entityItemSelectorMap[selector]
--   end
-- end

-- function entityFinder.getItemFromGround(itemSelector, gridPosition, componentRequirements) --luacheck: ignore
--   local items = entityFinder.getItemsOnGround(itemSelector, componentRequirements)
--   print("Any items anywhere?", itemSelector, items, #items)
--   if not items then return nil end
-- 
--   for _, item in ipairs(items) do
--     local position = positionUtils.pixelsToGridCoordinates(item.position.vector)
--     --print("Position", inspect(position))
--     if positionUtils.isInPosition(gridPosition, position, true) then
--       return item
--     end
--   end
-- 
--   return nil -- Could not find item on ground
-- end

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
