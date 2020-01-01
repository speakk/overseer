local bitser = require('libs.bitser')
local inspect = require('libs.inspect')
local entityReferenceManager = require('models.entityReferenceManager')

local SerializationSystem = ECS.System({ECS.Components.serialize}, {ECS.Components.id, 'ids'})

local function onIdAdded(pool, entity) --luacheck: ignore
  local id = entity:get(ECS.Components.id).id
  entityReferenceManager.set(id, entity)
end

local function onIdRemoved(pool, entity) --luacheck: ignore
  local id = entity:get(ECS.Components.id).id
  entityReferenceManager.remove(id)
end

local function serializeComponent(component)
  if component['serialize'] then
    return component:serialize()
  else
    return {}
  end
end

local function serializeComponents(entity)
  local serialized = {}
  for _, component in pairs(entity:getComponents()) do
    serialized[component.__baseComponent.__component_name] = serializeComponent(component)
  end

  return serialized
end

local function serializeEntity(entity)
  return {
    components = serializeComponents(entity)
  }
end

local function serializeEntities(entities)
  local serialized = {}

  for id, entity in pairs(entities) do
    serialized[id] = serializeEntity(entity)
  end

  return serialized
end

function SerializationSystem:init() --luacheck: ignore
  self.ids.onEntityAdded = onIdAdded
  self.ids.onEntityRemoved = onIdRemoved
end

function SerializationSystem:serializeState() --luacheck: ignore
  self:getWorld():__flush()
  return bitser.dumps({
    entities = serializeEntities(entityReferenceManager.getEntities())
  })
end

local function deserializeEntities(entityShells)
  local entities = {}

  for id, entityShell in pairs(entityShells) do
    local entity = ECS.Entity()
    for componentName, componentData in pairs(entityShell.components) do
      local baseComponent = ECS.Components[componentName]
      if baseComponent["deserialize"] then
        local params = { baseComponent.deserialize(componentData) }
        print("PARAMS", componentName, componentData, inspect(params))
        entity:give(baseComponent, unpack(params))
      else 
        entity:give(baseComponent)
      end
    end

    table.insert(entities, entity)
  end

  return entities
end

function SerializationSystem:deserialize(data)
  local deserialized = bitser.loads(data)

  local entities = deserializeEntities(deserialized.entities)

  for _, entity in ipairs(entities) do
    self:getWorld():addEntity(entity)
  end

  return deserialized
end

return SerializationSystem
