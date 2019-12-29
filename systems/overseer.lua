local universe = require('models.universe')
local camera = require('models.camera')

local Vector = require('libs.brinevector')
local lume = require('libs.lume')

local constructionTypes = require('data.constructionTypes')
local settings = require('settings')

local OverseerSystem = ECS.System()


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
    build = function(gridCoordinates) self:build(gridCoordinates) end
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
    camera:draw(function(l,t,w,h) --luacheck: ignore
      if (drag.type == "construct") then
        love.graphics.setColor(1, 1, 1, 1)
      else
        love.graphics.setColor(1, 0.2, 0.2, 1)
      end
      love.graphics.rectangle("line",
        startPoint.x,
        startPoint.y,
        endPoint.x - startPoint.x,
        endPoint.y - startPoint.y
        )
    end)
  end
end

function OverseerSystem:setDataSelector(selector)
  self.dataSelector = selector
  --self:getWorld():emit("dataSelectorChanged", selector)
end

function OverseerSystem:getDataSelector()
  return self.dataSelector
end

function OverseerSystem:setSelectedAction(selector)
  self.selectedAction = selector
end

function OverseerSystem:getSelectedAction()
  return self.selectedAction
end

function OverseerSystem:update(dt) --luacheck: ignore
end

function OverseerSystem:enactDrag(dragEvent)
  local gridCoordsStart = universe.pixelsToGridCoordinates(dragEvent.startPoint)
  local gridCoordsEnd = universe.pixelsToGridCoordinates(dragEvent.endPoint)
  
    local nodes = universe.iter(
    math.min(gridCoordsStart.x, gridCoordsEnd.x),
    math.min(gridCoordsStart.y, gridCoordsEnd.y),
    math.max(gridCoordsStart.x, gridCoordsEnd.x),
    math.max(gridCoordsStart.y, gridCoordsEnd.y))

  if dragEvent.type == 'construct' then
    self:build(nodes)
  elseif dragEvent.type == 'destruct' then
    self:destruct(nodes)
  end
end

function OverseerSystem:startDrag(mouseCoordinates, type) --luacheck: ignore
  drag.type = type
  drag.active = true
  drag.startPoint = mouseCoordinates
end

function OverseerSystem:endDrag(mouseCoordinates)
  drag.active = false
  drag.endPoint = mouseCoordinates
  self:enactDrag(drag)
end

function OverseerSystem:enactClick(mouseCoordinates, button)
  local type = button == 1 and "construct" or "destruct"
  if self.selectedAction == "build" then
    if settings.mouse_toggle_construct then
      if drag.active then
        self:endDrag(mouseCoordinates)
      else
        self:startDrag(mouseCoordinates, type)
      end
    else
      -- TODO: Also make actual drag & drop, for now the one below
      -- is just a placeholder (individual clicks
      if self.selectedAction and self.actionCallbacks[self.selectedAction] then
        self.actionCallbacks[self.selectedAction](mouseCoordinates)
      end
    end
  end
end

function OverseerSystem:build(nodes)
  local data = constructionTypes.getBySelector(self.dataSelector)
  self:getWorld():emit("bluePrintsPlaced", nodes, data, self.dataSelector)
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

