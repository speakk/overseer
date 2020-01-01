local lume = require('libs.lume')

local currentId = 0

local entities = {}

local callBacks = {}

local function registerReference(callBack)
  table.insert(callBacks, callBack)
end

local function initializeReferences()
  for _, callBack in ipairs(callBacks) do
    callBack(entities)
  end
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
  initializeReferences = initializeReferences,
  getEntities = function() return entities end,
  set = set,
  generateId = generateId,
  remove = remove
}
