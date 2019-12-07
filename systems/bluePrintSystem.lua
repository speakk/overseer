--local inspect = require('libs/inspect')
local commonComponents = require('components/common')
-- Create a draw System.
local BluePrintSystem = ECS.System({commonComponents.BluePrint})

function BluePrintSystem:generateBluePrintJob(gridPosition, itemData)
  local job = ECS.Entity()
  job:give(commonComponents.Job)
  job:give(commonComponents.BluePrintJob)
  job:give(commonComponents.Draw, itemData.color)
  job:give(commonComponents.Item, itemData)
  job:give(commonComponents.Position, self.mapSystem:gridPositionToPixels(gridPosition))

  if itemData.requirements then
    job:give(commonComponents.Children, {})
    local children = job:get(commonComponents.Children).children
    for selector, amount in pairs(itemData.requirements) do
      local subJob = ECS.Entity()
      subJob:give(commonComponents.Job)
      subJob:give(commonComponents.Item, itemData)
      subJob:give(commonComponents.FetchJob, job, selector, amount)
      subJob:apply()
      table.insert(children, subJob)
      self:getInstance():addEntity(subJob)
    end
  end

  job:apply()
  self:getInstance():addEntity(job)

  return job
end

-- function BluePrintSystem:generateBluePrint(gridPosition, constructionType)
--   print("constructionType", inspect(constructionType))
--   local bluePrint = ECS.Entity()
--   bluePrint:give(commonComponents.Item, constructionType)
--   bluePrint:give(commonComponents.Position, self.mapSystem:gridPositionToPixels(gridPosition))
--   bluePrint:give(commonComponents.Draw, constructionType.color)
--   bluePrint:give(commonComponents.BluePrintJob)
--   bluePrint:give(commonComponents.BluePrintJob)
--   bluePrint:apply()
--   return bluePrint
-- end


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
      --print("gridPosition", inspect(gridPosition))
      local bluePrint = self:generateBluePrintJob(gridPosition, constructionType)
      self:getInstance():emit("blueprintActivated", bluePrint)
    end

end

return BluePrintSystem
