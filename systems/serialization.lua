local entityReferenceManager = require('models.entityReferenceManager')

local SerializationSystem = ECS.System({ECS.Components.serialize}, {ECS.Components.id, 'ids'})

local function onIdAdded(pool, entity)
  local id = entity:get(ECS.Components.id).id
  entityReferenceManager.set(id, entity)
end

local function onIdRemoved(pool, entity)
  local id = entity:get(ECS.Components.id).id
  entityReferenceManager.remove(id)
end

local function serializeComponent(component)
  return component.serialize()
end

local function serializeComponents(entity)
  local serialized = {}
  for _, component in entity:getComponents() do
    table.insert(serialized, serializeComponent(component))
  end

  return serialized
end

local function serializeEntity(entity)
  local serializedComponents = serializeComponents(entity)
  return {
    components: serializeComponents
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

function SerializationSystem:serializeState()
  return {
    entities: serializeEntities(entityReferenceManager.getEntities())
  }
end
