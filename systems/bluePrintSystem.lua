local inspect = require('libs/inspect')
local commonComponents = require('components/common')
-- Create a draw System.
local BluePrintSystem = ECS.System({commonComponents.BluePrint})

function BluePrintSystem:generateBluePrint(gridPosition, constructionType)
  print("constructionType", inspect(constructionType))
  local bluePrint = ECS.Entity()
  bluePrint:give(commonComponents.Item, constructionType)
  bluePrint:give(commonComponents.Position, self.mapSystem:gridPositionToPixels(gridPosition))
  bluePrint:give(commonComponents.Draw, constructionType.color)
  bluePrint:give(commonComponents.BluePrintJob)
  bluePrint:apply()
  return bluePrint
end


function BluePrintSystem:init(mapSystem)
  self.mapSystem = mapSystem
end

function BluePrintSystem:update(dt) --luacheck: ignore
end

function BluePrintSystem:bluePrintFinished(bluePrint) --luacheck: ignore
  if bluePrint:has(commonComponents.Draw) then
    local draw = bluePrint:get(commonComponents.Draw)
    draw.color = { 1, 0, 0 }
  end
end

function BluePrintSystem:placeBluePrint(gridPosition, constructionType)
    gridPosition = self.mapSystem:clampToWorldBounds(gridPosition)
    if self.mapSystem:isCellAvailable(gridPosition) then
      local bluePrint = self:generateBluePrint(gridPosition, constructionType)
      self:getInstance():addEntity(bluePrint)
      self:getInstance():emit("blueprintActivated", bluePrint)
    end

end

return BluePrintSystem
