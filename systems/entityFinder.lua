local inspect = require 'libs.inspect'
local entityFinder = require 'models.entityFinder'

local pools = {}
functional.foreach(table.keys(entityFinder.indices), function(indexKey)
  --print("indexKey", indexKey, inspect({ [indexKey] = entityFinder.indices[indexKey].components }))
  pools[indexKey] = entityFinder.indices[indexKey].components
end)

print("pools", inspect(pools))
local EntityFinderSystem = ECS.System(pools)

function EntityFinderSystem:init()
  for key, pool in pairs(pools) do
    self[key].onEntityAdded = function(_, entity) entityFinder.indices[key].indexFunction(entity) end
    self[key].onEntityRemoved = function(_, entity) entityFinder.indices[key].indexFunction(entity, true) end
  end
end

return EntityFinderSystem
