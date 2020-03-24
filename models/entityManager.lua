local lume = require('libs.lume')

local entities = {}
local references = {}

local function onEntityRemoved(entity)
  local id = entity.id.id
  references[id] = nil
  entities[id] = nil
end

local function onEntityAdded(entity)
  local id = entity.id.id
  if not id then error "No ID for entity on removal" end
  entities[id] = entity
end

local function registerReference(referenceId, onRemove)
  references[referenceId] = references[referenceId] or {}
  table.insert(references[referenceId], onRemove)
end

local function get(referenceId)
  return entities[referenceId]
end

local function generateId()
  return lume.uuid()
end

local function clear()
  for k,_ in pairs(entities) do
    entities[k] = nil
  end

  for k,_ in pairs(references) do
    references[k] = nil
  end
end

return {
  registerReference = registerReference,
  onEntityAdded = onEntityAdded,
  onEntityRemoved = onEntityRemoved,
  get = get,
  clear = clear,
  generateId = generateId,
  getEntities = function()
  --  print("All entities!")
  --  for id, entity in pairs(entities) do
  --    local jobtext = ""
  --    if entity.job then
  --      jobtext = entity.job.jobType
  --    end
  --    print("Entity:", id, entity, jobtext)
  --  end
    return entities
  end,
}
