local utils = require('utils.utils')
local nuklear = require("nuklear")
local bitser = require('libs.bitser')
local inspect = require('libs.inspect')
local settings = require('settings')
local entityManager = require('models.entityManager')

local debugFont = love.graphics.newFont(12)

local ui

local SerializationSystem = ECS.System({ ids = { "id" } })

local function onIdAdded(pool, entity) --luacheck: ignore
  local id = entity.id.id
  entityManager.onEntityAdded(entity)
  --entityManager.set(id, entity)
end

local function onIdRemoved(pool, entity) --luacheck: ignore
  local id = entity.id.id
  entityManager.onEntityRemoved(entity)
  --entityManager.removeByEntity(entity, id)
end

local function serializeComponent(component)
  if component['customSerialize'] then
    return component:customSerialize()
  else
    return {}
  end
end

local function serializeComponents(entity)
  local serialized = {}
  for _, component in pairs(entity:getComponents()) do
    serialized[component:getName()] = serializeComponent(component)
  end

  return serialized
end

local function serializeEntity(entity)
  local compstring = ''
  for cid, component in pairs(entity:getComponents()) do
    compstring = compstring ..  component:getName() .. " | "
  end
  return {
    components = serializeComponents(entity)
  }
end

local function serializeEntities(entities)
  local serialized = {}

  for _, entity in pairs(entities) do
    local id = entity.id.id
    print("OKAY ID", id)
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
    entities = serializeEntities(entityManager.getEntities())
  }),
  inspect(serializeEntities(entityManager.getEntities()))
end

local function deserializeEntities(entityShells)
  local entities = {}

  for id, entityShell in pairs(entityShells) do
    local entity = ECS.Entity()
    for componentName, componentData in pairs(entityShell.components) do
      local baseComponent = componentName
      if baseComponent["customDeserialize"] then
        local component = baseComponent.customDeserialize(componentData)
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

function SerializationSystem:saveGame(filename)
  local state, insp = self:serializeState()
  love.filesystem.write(filename, state)
  love.filesystem.write('savetestPlain', insp)
  print("Saved?", filename)
end

function SerializationSystem:loadGame(saveName)
  print("Loading", saveName)
  local saveName = saveName or 'overseer_quicksave'
  --local settlerSystem = self:getWorld():getSystem(ECS.Systems.settler)
  --self:getWorld():disableSystem(settlerSystem)
  self:getWorld():clear()
  entityManager.clear()
  self:getWorld():__flush()

  local file = love.filesystem.read(saveName)
  local entities = self:deserialize(file)

  for _, entity in ipairs(entities) do
    self:getWorld():addEntity(entity)
  end

  self:getWorld():__flush()

  --entityManager.initializeReferences()
  --self:getWorld():enableSystem(settlerSystem)
end

function createEntityHierarchy(entity, depthLimit, depth)
  depth = depth + 1
  if depth > depthLimit then return nil end

  if depth == 0 and entity.parent then return nil end

  --print("What is entity?", entity)

  --local id = tostring(entity.id.id) .. " / " .. tostring(entity)
  local id = tostring(entity)
  if entity.children then
    id = id .. "*"
  end
  if entity.name then
    id = id .. " (" .. entity.name.name .. ")"
  end
  if ui:treePush('tab', id) then
    if not entity.children then
      local components = entity:getComponents()
      for cid, component in pairs(components) do
        local selected = false
        local name = component:getName() .. " / " .. tostring(component)
        if ui:selectable(name, selected) then
        end
        for _, prop in pairs(component) do
          if type(prop) == "table" and prop["has"] then
            createEntityHierarchy(prop, depthLimit, depth)
          end
        end
      end
    else
      for _, kid in ipairs(entity.children.children) do
        if type(kid) == "table" and kid["has"] then
          createEntityHierarchy(kid, depthLimit, depth)
        end
      end
    end
    ui:treePop()
  end
end

function SerializationSystem:update(dt)
  if not DEBUG then return end

  ui:frameBegin()
  ui:stylePush({
    ['font'] = debugFont
  })
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()
  local entityWindowWidth = settings.entity_debugger_width
  local entityWindowHeight = windowHeight

  if ui:windowBegin('entityWindow', windowWidth-entityWindowWidth, 0, entityWindowWidth, entityWindowHeight, 'scrollbar') then
    for id, entity in pairs(entityManager.getEntities()) do
      createEntityHierarchy(entity, 4, 0)
    end
    ui:windowEnd()
  end

  ui:stylePop()
  ui:frameEnd()
end

function SerializationSystem:generateGUIDraw()
  if not DEBUG then return end
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
