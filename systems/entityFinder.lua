local entityFinder = require 'models.entityFinder'

local pools = functional.map(table.keys(entityFinder.indices), function(indexKey)
  return { [indexKey] = entityFinder.indices[indexKey].components }
end)

local EntityFinderSystem = ECS.System(pools)

function EntityFinderSystem:init()
  for key, pool in pairs(pools) do
    self.pools[key].onEntityAdded = function(_, entity) entityFinder.indices[key].indexFunction(entity) end
    self.pools[key].onEntityRemoved = function(_, entity) entityFinder.indices[key].indexFunction(entity, true) end
  end
end
