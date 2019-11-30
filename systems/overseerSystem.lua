local Vector = require('libs/brinevector/brinevector')
local cpml = require('libs/cpml')
local lume = require('libs/lume')
local inspect = require('libs/inspect')
local commonComponents = require('components/common')

local OverseerSystem = ECS.System()

local constructionTypes = require('data/constructionTypes')

function getDataWithSelector(data, selectorTable)
  if #selectorTable == 0 then return data end
  local newTable = {unpack(selectorTable)}
  local lastSelector = table.remove(newTable, 1)
  --print("lastSelector", lastSelector)
  return getDataWithSelector(data[lastSelector], newTable)
end


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
  self.dataSelector = { "build", "subItems", "walls", "subItems", "wooden_wall" }
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
  self.actionCallbacks[self.selectedAction](gridCoordinates)
end

function OverseerSystem:build(gridCoordinates)
  local dataSelector = lume.clone(self.dataSelector)
  table.remove(dataSelector, 1)
  print("dataSelector", inspect(dataSelector))
  local data = getDataWithSelector(constructionTypes, dataSelector)
  self.bluePrintSystem:placeBluePrint(gridCoordinates, data)
end

return OverseerSystem

