local positionUtils = require('utils.position')
local entityFinder = require('models.entityFinder')
local camera = require('models.camera')

local entityRegistry = require('models.entityRegistry')

local Vector = require('libs.brinevector')
local lume = require('libs.lume')
local inspect = require('libs.inspect') --luacheck: ignore

local settings = require('settings')

local OverseerSystem = ECS.System()

local zoneColor = { 0.3, 0.3, 0.9, 0.5 }

local function getNewDragAction()
  return {
    startPoint = Vector(),
    endPoint = Vector(),
    active = false
  }
end

local drag = getNewDragAction()

function OverseerSystem:generateGUIDraw() --luacheck: ignore
  if drag.active then
    local globalX, globalY = camera:toWorld(love.mouse.getX(), love.mouse.getY())
    local startPixels = drag.startPoint
    local left = math.min(startPixels.x, globalX)
    local top = math.min(startPixels.y, globalY)
    local right = math.max(startPixels.x, globalX)
    local bottom = math.max(startPixels.y, globalY)
    local startPoint = positionUtils.snapPixelToGrid(Vector(left, top), "left_top", 0)
    local endPoint = positionUtils.snapPixelToGrid(Vector(right, bottom), "right_bottom", 0)
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

function OverseerSystem:enactDrag(dragEvent) --luacheck: ignore
  if not dragEvent or not dragEvent.action then print("uh what") return end
  local gridCoordsStart = positionUtils.pixelsToGridCoordinates(dragEvent.startPoint)
  local gridCoordsEnd = positionUtils.pixelsToGridCoordinates(dragEvent.endPoint)

  local coords = positionUtils.getOuterBorderCoordinates(
  math.min(gridCoordsStart.x, gridCoordsEnd.x),
  math.min(gridCoordsStart.y, gridCoordsEnd.y),
  math.max(gridCoordsStart.x, gridCoordsEnd.x),
  math.max(gridCoordsStart.y, gridCoordsEnd.y),
  dragEvent.fill)

  dragEvent.action(coords, {
    x1 = gridCoordsStart.x,
    y1 = gridCoordsStart.y,
    x2 = gridCoordsEnd.x,
    y2 = gridCoordsEnd.y
  })
end

function OverseerSystem:startDrag(mouseCoordinates, fill, action) --luacheck: ignore
  drag.action = action
  drag.fill = fill
  drag.active = true
  drag.startPoint = mouseCoordinates
end

function OverseerSystem:endDrag(mouseCoordinates)
  drag.active = false
  drag.endPoint = mouseCoordinates
  self:enactDrag(drag)
end

function OverseerSystem:buildClick(globalX, globalY, button, params)
  local mouseCoordinates = Vector(globalX, globalY)

  if button == 1 then
    self:dragAction(mouseCoordinates, button, false, function(coords, rect) --luacheck: ignore
      self:build(coords, params.assembleFunction)
    end,
    { 1, 1, 1, 1 })
  else
    self:dragAction(mouseCoordinates, button, true, function(coords, rect) --luacheck: ignore
      self:destruct(coords)
    end,
    { 1, 0, 0, 1 })
  end
end

function OverseerSystem:dragAction(mouseCoordinates, button, fill, callBack, color) --luacheck: ignore
  if settings.mouse_toggle_drag then
    if drag.active then
      self:endDrag(mouseCoordinates)
    else
      drag.color = color
      self:startDrag(mouseCoordinates, fill, callBack)
    end
  else
    drag.color = color
    self:startDrag(mouseCoordinates, fill, callBack)
  end
end

function OverseerSystem:mouseReleased(mouseCoordinates, button) --luacheck: ignore
  if not drag.active then return end

  if not settings.mouse_toggle_construct then
    self:endDrag(mouseCoordinates)
  end
end

function OverseerSystem:build(coords, assemblage)
  print("Build", assemblage)
  if not assemblage then return end
  self:getWorld():emit("bluePrintsPlaced", coords, assemblage)
end

function OverseerSystem:zonesClick(globalX, globalY, button, params)
  local mouseCoordinates = Vector(globalX, globalY)
  if button == 1 then
    self:dragAction(mouseCoordinates, button, true, function(coords, rect)
      self:zones(coords, rect, params)
    end,
    zoneColor)
  else
    self:getWorld():emit("zoneDeleteClick", mouseCoordinates)
  end
end

function OverseerSystem:zones(coords, rect, params) --luacheck: ignore
  local zoneEntity = ECS.Entity()
  zoneEntity:give("id", entityRegistry.generateId())
  zoneEntity:give("zone", params.types, params)
  zoneEntity:give("color", zoneColor)
  zoneEntity:give("rect", rect.x1, rect.y1, rect.x2, rect.y2)

  self:getWorld():addEntity(zoneEntity)
end

function OverseerSystem:destruct(coords)
  local allEntities = {}
  for _, position in ipairs(coords) do
    --local gridPosition = positionUtils.clampToWorldBounds(position)
    --local entities = entityFinder.getEntitiesInLocation(position)
    local entities = entityFinder.getEntities("position", entityFinder.getGridPositionString(position))
    allEntities = lume.concat(allEntities, entities)
  end
  self:getWorld():emit("cancelConstruction", allEntities)
end

return OverseerSystem
