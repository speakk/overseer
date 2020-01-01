local lume = require('libs.lume')

local currentId = 0

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

local function generateId()
  currentId = currentId + 1
  return currentId
end

return {
  registerReference = registerReference,
  getEntities = function() return entities end,
  set = set,
  generateId = generateId,
  remove = remove
}
