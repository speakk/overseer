local universe = require('models.universe')
local camera = require('models.camera')

local entityReferenceManager = require('models.entityReferenceManager')

local Vector = require('libs.brinevector')
local lume = require('libs.lume')
local inspect = require('libs.inspect')

local constructionTypes = require('data.constructionTypes')
local settings = require('settings')

local OverseerSystem = ECS.System()

local zoneColor = { 0.3, 0.3, 0.9, 1.0 }


local drag = {
  startPoint = Vector(),
  endPoint = Vector(),
  active = false
}

function OverseerSystem:init()
  self.resources = {
    wood = 30,
    metal = 5
  }

  self.actionCallbacks = {
    build = {
      action1 = function(mouseCoordinates, button)
        --actions.action1(mouseCoordinates, button)
        self:dragAction(mouseCoordinates, button, function(nodes, rect)
          self:build(nodes)
        end,
        { 1, 1, 1, 1 })
      end,
      action2 = function(mouseCoordinates, button)
        self:dragAction(mouseCoordinates, button, function(nodes, rect)
          self:destruct(nodes)
        end,
        { 1, 0, 0, 1 })
      end,
    },
    zones = {
      action1 = function(mouseCoordinates, button)
        self:dragAction(mouseCoordinates, button, function(nodes, rect)
          self:zones(nodes, rect)
        end,
        zoneColor)
      end
    }
  }

  self.selectedAction = ""
  self.dataSelector = "walls.subItems.wooden_wall"
end

function OverseerSystem:generateGUIDraw() --luacheck: ignore
  if drag.active then
    local globalX, globalY = camera:toWorld(love.mouse.getX(), love.mouse.getY())
    local startPixels = drag.startPoint
    local left = math.min(startPixels.x, globalX)
    local top = math.min(startPixels.y, globalY)
    local right = math.max(startPixels.x, globalX)
    local bottom = math.max(startPixels.y, globalY)
    local startPoint = universe.snapPixelToGrid(Vector(left, top), "left_top", 0)
    local endPoint = universe.snapPixelToGrid(Vector(right, bottom), "right_bottom", 0)
    local camStart = Vector(camera:toScreen(startPoint.x, startPoint.y))
    local camEnd = Vector(camera:toScreen(endPoint.x, endPoint.y))
    --camera:draw(function(l,t,w,h) --luacheck: ignore
      -- if (drag.type == "construct") then
      --   love.graphics.setColor(1, 1, 1, 1)
      -- else
      --   love.graphics.setColor(1, 0.2, 0.2, 1)
      -- end
      if drag.color then
        love.graphics.setColor(unpack(drag.color))
      else
        love.graphics.setColor(1, 1, 1, 1)
      end

      love.graphics.rectangle("line",
        camStart.x,
        camStart.y,
        camEnd.x - camStart.x,
        camEnd.y - camStart.y
        )
    --end)
  end
end

function OverseerSystem:dataSelectorChanged(selector)
  self.dataSelector = selector
  --self:getWorld():emit("dataSelectorChanged", selector)
end

function OverseerSystem:getDataSelector()
  return self.dataSelector
end

function OverseerSystem:selectedModeChanged(selector)
  self.selectedAction = selector
end

function OverseerSystem:getSelectedAction()
  return self.selectedAction
end

function OverseerSystem:update(dt) --luacheck: ignore
end

function OverseerSystem:enactDrag(dragEvent)
  if not dragEvent or not dragEvent.action then print("uh what") return end
  local gridCoordsStart = universe.pixelsToGridCoordinates(dragEvent.startPoint)
  local gridCoordsEnd = universe.pixelsToGridCoordinates(dragEvent.endPoint)

  local nodes = universe.iter(
  math.min(gridCoordsStart.x, gridCoordsEnd.x),
  math.min(gridCoordsStart.y, gridCoordsEnd.y),
  math.max(gridCoordsStart.x, gridCoordsEnd.x),
  math.max(gridCoordsStart.y, gridCoordsEnd.y))

  dragEvent.action(nodes, {
    x1 = gridCoordsStart.x,
    y1 = gridCoordsStart.y, 
    x2 = gridCoordsEnd.x, 
    y2 = gridCoordsEnd.y 
  })

  -- if dragEvent.type == 'construct' then
  --   self:build(nodes)
  -- elseif dragEvent.type == 'destruct' then
  --   self:destruct(nodes)
  -- end
end

function OverseerSystem:startDrag(mouseCoordinates, action) --luacheck: ignore
  drag.action = action
  drag.active = true
  drag.startPoint = mouseCoordinates
end

function OverseerSystem:endDrag(mouseCoordinates)
  drag.active = false
  drag.endPoint = mouseCoordinates
  self:enactDrag(drag)
end

function OverseerSystem:mapClicked(mouseCoordinates, button, actionType)
  if not actionType then return end
  local actions = self.actionCallbacks[actionType]
  if button == 1 then
    actions.action1(mouseCoordinates, button)
  else
    actions.action2(mouseCoordinates, button)
  end
  --self:mapClicked(mouseCoordinates, button, actions.action1, actions.action2)
end

function OverseerSystem:dragAction(mouseCoordinates, button, callBack, color)
  if settings.mouse_toggle_drag then
    if drag.active then
      self:endDrag(mouseCoordinates)
    else
      drag.color = color
      self:startDrag(mouseCoordinates, callBack)
    end
  else
    drag.color = color
    self:startDrag(mouseCoordinates, callBack)
  end
end

function OverseerSystem:mouseReleased(mouseCoordinates, button) --luacheck: ignore
  if not settings.mouse_toggle_construct then
    self:endDrag(mouseCoordinates)
  end
end

function OverseerSystem:build(nodes)
  local data = constructionTypes.getBySelector(self.dataSelector)
  self:getWorld():emit("bluePrintsPlaced", nodes, data, self.dataSelector)
end

function OverseerSystem:zones(nodes, rect)
  local zoneEntity = ECS.Entity()
  zoneEntity:give(ECS.Components.id, entityReferenceManager.generateId())
  zoneEntity:give(ECS.Components.zone)
  zoneEntity:give(ECS.Components.color, zoneColor)
  zoneEntity:give(ECS.Components.rect, rect.x1, rect.y1, rect.x2, rect.y2)

  self:getWorld():addEntity(zoneEntity)
end

function OverseerSystem:destruct(nodes)
  local allEntities = {}
  for node, _ in nodes do
    local gridPosition = universe.clampToWorldBounds(Vector(node:getX(), node:getY()))
    local entities = universe.getEntitiesInLocation(gridPosition)
    allEntities = lume.concat(allEntities, entities)
  end
  self:getWorld():emit("cancelConstruction", allEntities)
end

return OverseerSystem

