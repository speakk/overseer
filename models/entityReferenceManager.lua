local lume = require('libs.lume')

local entities = {}

local function registerReference(callBack)
  callBack(entities)
end

local function set(id, entity)
  entities[id] = entity
end

local function remove(id)
  table.remove(entities, id)
end

return {
  registerReference = registerReference,
  getEntities = function() return entities end,
  set = set,
  remove = remove
}
