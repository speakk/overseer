local commonComponents = require('components/common')
-- Create a draw System.
local BluePrintSystem = ECS.System({commonComponents.BluePrint})

function BluePrintSystem:generateBluePrint(gridPosition, constructionType)
  local bluePrint = ECS.Entity()
  bluePrint:give(commonComponents.Position, self.mapSystem:gridPositionToPixels(gridPosition))
  bluePrint:give(commonComponents.Draw, constructionType.color)
  bluePrint:give(commonComponents.BluePrint)
  bluePrint:apply()
  return bluePrint
end


function BluePrintSystem:init(mapSystem)
  self.mapSystem = mapSystem
end

function BluePrintSystem:update(dt)
  
end

function BluePrintSystem:bluePrintFinished(bluePrint)
  if bluePrint:has(commonComponents.Draw) then
    local draw = bluePrint:get(commonComponents.Draw)
    draw.color = { 1, 0, 0 }
  end
end

function BluePrintSystem:placeBluePrint(gridPosition, constructionType)
    local bluePrint = ECS.Entity()
    local worldSize = self.mapSystem:getSize()
    gridPosition = self.mapSystem:clampToWorldBounds(gridPosition)
    if self.mapSystem:isCellAvailable(gridPosition) then
      print("ASD!")
      print("Position", gridPosition)
      print("In pixels", self.mapSystem:gridPositionToPixels(gridPosition))
      local bluePrint = self:generateBluePrint(gridPosition, constructionType)
      self:getInstance():addEntity(bluePrint)
      self:getInstance():emit("blueprintActivated", bluePrint)
    end

end

return BluePrintSystem
