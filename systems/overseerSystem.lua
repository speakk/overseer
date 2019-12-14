local OverseerSystem = ECS.System()

local Vector = require('libs/brinevector/brinevector')

local constructionTypes = require('data.constructionTypes')
local settings = require('settings')

local drag = {
  startPoint = Vector(),
  endPoint = Vector(),
  active = false
}

function OverseerSystem:init(bluePrintSystem, mapSystem, camera)
  self.bluePrintSystem = bluePrintSystem
  self.mapSystem = mapSystem
  self.camera = camera
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

function OverseerSystem:draw()
  local cellSize = self.mapSystem:getCellSize()
  if drag.active then
    local startPoint = self.mapSystem:gridPositionToPixels(drag.startPoint)
    local globalX, globalY = self.camera:toWorld(love.mouse.getX(), love.mouse.getY())
    -- TODO: Now adding cellSize to make sure visuals correspond to actual. Find out why this needs to happen, probably has to do with how rounding is done in "pixelsToGridCoordinates"
    local gridSnappedMouse = self.mapSystem:snapPixelToGrid(Vector(globalX+cellSize, globalY+cellSize))
    self.camera:draw(function(l,t,w,h)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("line",
        startPoint.x,
        startPoint.y,
        gridSnappedMouse.x - startPoint.x,
        gridSnappedMouse.y - startPoint.y
        )
    end)
  end
end

function OverseerSystem:setDataSelector(selector)
  self.dataSelector = selector
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

function OverseerSystem:enactConstructionDrag(dragEvent)
  local nodes = self.mapSystem:iter(
  dragEvent.startPoint.x,
  dragEvent.startPoint.y,
  dragEvent.endPoint.x,
  dragEvent.endPoint.y)

  self:build(nodes)
end

function OverseerSystem:startConstructionDrag(gridCoordinates) --luacheck: ignore
  drag.active = true
  drag.startPoint = gridCoordinates
end

function OverseerSystem:endConstructionDrag(gridCoordinates)
  drag.active = false
  drag.endPoint = gridCoordinates
  self:enactConstructionDrag(drag)
end

function OverseerSystem:enactClick(gridCoordinates)
  if self.selectedAction == "build" then
    if settings.mouse_toggle_construct then
      if drag.active then
        self:endConstructionDrag(gridCoordinates)
      else
        self:startConstructionDrag(gridCoordinates)
      end
    else
      -- TODO: Also make actual drag & drop, for now the one below
      -- is just a placeholder (individual clicks
      if self.selectedAction and self.actionCallbacks[self.selectedAction] then
        self.actionCallbacks[self.selectedAction](gridCoordinates)
      end
    end
  end

end

function OverseerSystem:build(nodes)
  local data = constructionTypes.getBySelector(self.dataSelector)
  self.bluePrintSystem:placeBluePrints(nodes, data, self.dataSelector)
end

return OverseerSystem

