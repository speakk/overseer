local Vector = require('libs/brinevector/brinevector')
local cpml = require('libs/cpml')
local lume = require('libs/lume')
local inspect = require('libs/inspect')
local commonComponents = require('components/common')

local OverseerSystem = ECS.System()

local constructionTypes = require('data/constructionTypes')

function OverseerSystem:init(bluePrintSystem)
  self.bluePrintSystem = bluePrintSystem
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

function OverseerSystem:update(dt)
end

function OverseerSystem:enactClick(gridCoordinates)
  if self.selectedAction and self.actionCallbacks[self.selectedAction] then
    self.actionCallbacks[self.selectedAction](gridCoordinates)
  end
end

function OverseerSystem:build(gridCoordinates)
  local data = constructionTypes.getBySelector(self.dataSelector)
  self.bluePrintSystem:placeBluePrint(gridCoordinates, data)
end

return OverseerSystem

