local lume = require('libs.lume')
local inspect = require('libs.inspect') --luacheck: ignore
local positionUtils = require('utils.position')

local entityFinder = {}

entityFinder.makeIndexFunction = function(key, indexKeyFunction)
  return function(entity, remove)
    local indexes = indexKeyFunction(entity)
    print("indexes type", type(indexes))
    if type(indexes) ~= 'table' then
      print("Not table, making table, right?")
      indexes = { indexes }
      print(indexes)
    end
    print("indexes", indexes)

    for _, index in ipairs(indexes) do
      if remove then
        print("Removing", key, index, entity)
        local items = entityFinder.indices[key].items[index]
        if not items then
          print("Tried to delete but was not there: key / index / entity", key, index, entity)
        end
        table.remove_value(items, entity)
      else
        local items = entityFinder.indices[key].items[index] or {}
        table.insert(items, entity)
        entityFinder.indices[key].items[index] = items
      end
    end
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
        selectorSoFar = selectorSoFar .. part
        table.insert(indices, selectorSoFar)
        selectorSoFar = selectorSoFar .. "."
      end
      return indices
    end),
    components = { "selector", "position" },
    items = {}
  }
}

function entityFinder.getEntities(indexKey, index, componentsFilter)
  print("Getting entities", indexKey, index, componentsFilter)
  local items = entityFinder.indices[indexKey].items[index]
  --print("Items with indexKey", indexKey, inspect(entityFinder.indices[indexKey].items, { depth = 1 }))
  print("Found entities? -> ", items)
  if items then
    print("Entities length:", #items)
  end

  if items and componentsFilter then
    items = entityFinder.filterByComponentList(items, componentsFilter)
  end

  return items or {}
end

function entityFinder.getByList(indexPairs, componentsFilter)
  return functional.reduce(indexPairs, function(result, indexPair)
    print("value coord", indexPair.key, indexPair.value)
    local indexKey = indexPair.key
    local indexValue = indexPair.value
    local items = entityFinder.indices[indexKey].items[indexValue]
    --print("Items with indexKey", indexKey, inspect(entityFinder.indices[indexKey].items, { depth = 1 }))
    print("Found entities? -> ", items)
    if items then
      print("Entities length:", #items)
    end

    if items and componentsFilter then
      items = entityFinder.filterByComponentList(items, componentsFilter)
    end

    return table.append_inplace(result, items or {})
  end, {})
end

function entityFinder.filterByComponentList(entities, componentsList)
  return functional.filter(entities, function(entity)
    for _, filter in ipairs(componentsList) do
      if not entity[filter] then return false end
    end
    return true
  end)
end

function entityFinder.filterBySelector(entities, selector)
  return functional.filter(entities, function(entity)
    return string.find(entity.selector.selector, '^' .. selector)
  end)
end

function entityFinder.isPositionOccupied(gridPosition)
  return entityFinder.indices.position[entityFinder.getGridPositionString(gridPosition)]
end

return entityFinder
