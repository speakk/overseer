local Vector = require('libs/brinevector/brinevector')
local cpml = require('libs/cpml')
local commonComponents = require('components/common')

local OverseerSystem = ECS.System()

local constructionTypes = require('data/constructionTypes')

function getDataWithSelector(data, selectorTable)
  if table.getn(selectorTable) == 1 then return data end
  local newTable = {unpack(selectorTable)}
  local lastSelector = table.remove(newTable, 1)
  return getDataWithSelector(data[lastSelector], newTable)
end


function OverseerSystem:init(bluePrintSystem)
  self.bluePrintSystem = bluePrintSystem
  self.resources = {
    wood = 30,
    metal = 5
  }

  self.actionCallbacks = {
    placeBluePrint = function(gridCoordinates) self:placeBluePrint(gridCoordinates) end
  }

  self.selectedAction = "placeBluePrint"
  self.dataSelector = { "walls", "types", "wooden_wall" }
end

function OverseerSystem:update(dt)
end

function OverseerSystem:enactClick(gridCoordinates)
  self.actionCallbacks[self.selectedAction](gridCoordinates)
end

function OverseerSystem:placeBluePrint(gridCoordinates)
  local data = getDataWithSelector(constructionTypes, self.dataSelector)
  print("Data", data)
  self.bluePrintSystem:placeBluePrint(gridCoordinates, data)
end

return OverseerSystem

