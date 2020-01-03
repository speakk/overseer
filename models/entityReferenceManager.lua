local lume = require('libs.lume')

local currentId = 0

local entities = {}

local callBacks = {}

local test = {}

local function registerReference(callBack)
  table.insert(callBacks, callBack)
end

local function initializeReferences()
  print("initialize references!")
  for _, callBack in ipairs(callBacks) do
    callBack(entities)
  end
end

local function set(id, entity)
  if id > currentId then
    currentId = id + 1
  end
  print("Adding/setting entity", id, entity, test, "currentId", currentId, "what")
  local compstring = ''
  for cid, component in pairs(entity:getComponents()) do
    compstring = compstring ..  component.__baseComponent.__component_name .. " | "
  end
  print("Components: ", compstring)
  if entities[id] then
    error ("Id already exists in entityReferenceManager, id: " .. tostring(id) .. " / " .. tostring(entity))
  end
  entities[id] = entity
end

local function removeById(id)
  table.remove(entities, id)
end

local function removeByEntity(entity)
  lume.remove(entities, entity)
end

local function generateId()
  currentId = currentId + 1
  return currentId
end

local function clear()
  for k,_ in pairs(entities) do
    entities[k] = nil
  end
  --entities = {}
  print("Clearing!")
end

return {
  registerReference = registerReference,
  initializeReferences = initializeReferences,
  clear = clear,
  getEntities = function()
    print("All entities!")
    for id, entity in pairs(entities) do
      local jobtext = ""
      if entity:has(ECS.Components.job) then
        jobtext = entity:get(ECS.Components.job).jobType
      end
      print("Entity:", id, entity, jobtext)
    end
    return entities
  end,
  set = set,
  generateId = generateId,
  removeByEntity = removeByEntity
}
