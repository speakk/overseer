local utils = require('utils.utils')
local nuklear = require("nuklear")
local bitser = require('libs.bitser')
local inspect = require('libs.inspect')
local entityReferenceManager = require('models.entityReferenceManager')

local debugFont = love.graphics.newFont(12)

local ui

local SerializationSystem = ECS.System({ECS.Components.serialize}, {ECS.Components.id, 'ids'})

local function onIdAdded(pool, entity) --luacheck: ignore
  local id = entity:get(ECS.Components.id).id
  entityReferenceManager.set(id, entity)
end

local function onIdRemoved(pool, entity) --luacheck: ignore
  local id = entity:get(ECS.Components.id).id
  entityReferenceManager.removeByEntity(entity)
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
  local compstring = ''
  for cid, component in pairs(entity:getComponents()) do
    compstring = compstring ..  component.__baseComponent.__component_name .. " | "
  end
  return {
    components = serializeComponents(entity)
  }
end

local function serializeEntities(entities)
  local serialized = {}

  for _, entity in ipairs(entities) do
    local id = entity:get(ECS.Components.id).id
    serialized[id] = serializeEntity(entity)
  end

  return serialized
end

function SerializationSystem:init() --luacheck: ignore
  self.ids.onEntityAdded = onIdAdded
  self.ids.onEntityRemoved = onIdRemoved
  ui = nuklear.newUI()
end

function SerializationSystem:serializeState() --luacheck: ignore
  return bitser.dumps({
    entities = serializeEntities(entityReferenceManager.getEntities())
  }),
  inspect(serializeEntities(entityReferenceManager.getEntities()))
end

local function deserializeEntities(entityShells)
  local entities = {}

  for id, entityShell in pairs(entityShells) do
    local entity = ECS.Entity()
    for componentName, componentData in pairs(entityShell.components) do
      local baseComponent = ECS.Components[componentName]
      if baseComponent["deserialize"] then
        local component = baseComponent.deserialize(componentData)
        entity:givePopulated(component)
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
  return deserializeEntities(deserialized.entities)
end

function SerializationSystem:saveGame()
  local state, insp = self:serializeState()
  love.filesystem.write('savetest', state)
  love.filesystem.write('savetestPlain', insp)
end

function SerializationSystem:loadGame()
  local settlerSystem = self:getWorld():getSystem(ECS.Systems.settler)
  self:getWorld():disableSystem(settlerSystem)
  self:getWorld():clear()
  entityReferenceManager.clear()
  self:getWorld():__flush()

  local file = love.filesystem.read('savetest')
  local entities = self:deserialize(file)

  for _, entity in ipairs(entities) do
    self:getWorld():addEntity(entity)
  end

  self:getWorld():__flush()

  entityReferenceManager.initializeReferences()
  self:getWorld():enableSystem(settlerSystem)
end

function createEntityHierarchy(entity, depthLimit, depth)
  depth = depth + 1
  if depth > depthLimit then return nil end

  if depth == 0 and entity:has(ECS.Components.parent) then return nil end

  local id = tostring(entity:get(ECS.Components.id).id) .. " / " .. tostring(entity)
  if entity:has(ECS.Components.children) then
    id = id .. "*"
  end
  if entity:has(ECS.Components.name) then
    id = id .. " (" .. entity:get(ECS.Components.name).name .. ")"
  end
  if ui:treePush('tab', id) then
    if not entity:has(ECS.Components.children) then
      local components = entity:getComponents()
      for cid, component in pairs(components) do
        local selected = false
        local name = component.__baseComponent.__component_name .. " / " .. tostring(component)
        if ui:selectable(name, selected) then
        end
        for _, prop in pairs(component) do
          if type(prop) == "table" and prop["has"] then
            createEntityHierarchy(prop, depthLimit, depth)
          end
        end
      end
    else
      for _, kid in ipairs(entity:get(ECS.Components.children).children) do
        createEntityHierarchy(kid, depthLimit, depth)
      end
    end
    ui:treePop()
  end
end

function SerializationSystem:update(dt)
  ui:frameBegin()
  ui:stylePush({
    ['font'] = debugFont
  })
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()
  local entityWindowWidth = 600
  local entityWindowHeight = windowHeight

  if ui:windowBegin('entityWindow', windowWidth-entityWindowWidth, 0, entityWindowWidth, entityWindowHeight, 'scrollbar') then
    for id, entity in pairs(entityReferenceManager.getEntities()) do
      createEntityHierarchy(entity, 4, 0)
    end
    ui:windowEnd()
  end

  ui:stylePop()
  ui:frameEnd()
end

function SerializationSystem:generateGUIDraw()
  ui:draw()
end

function SerializationSystem:mousepressed(x, y, button, istouch, presses)
  if ui:mousepressed(x, y, button, istouch, presses) then
    return
  end
end

function SerializationSystem:mousereleased(x, y, button, istouch, presses) --luacheck: ignore
  if ui:mousereleased(x, y, button, istouch, presses) then
    return
  end
end

function SerializationSystem:mousemoved(x, y, dx, dy, istouch) --luacheck: ignore
  ui:mousemoved(x, y, dx, dy, istouch)
end

return SerializationSystem
