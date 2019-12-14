--local inspect = require('libs/inspect')
local Vector = require('libs/brinevector/brinevector')
local commonComponents = require('components/common')
-- Create a draw System.
local BluePrintSystem = ECS.System({commonComponents.BluePrint})

function BluePrintSystem:generateBluePrintJob(gridPosition, itemData, bluePrintItemSelector)
  local job = ECS.Entity()
  job:give(commonComponents.Job)
  job:give(commonComponents.Name, "BluePrintJob")
  job:give(commonComponents.BluePrintJob)
  job:give(commonComponents.Draw, itemData.color)
  job:give(commonComponents.Item, itemData, bluePrintItemSelector)
  job:give(commonComponents.Position, self.mapSystem:gridPositionToPixels(gridPosition))
  job:give(commonComponents.Collision)

  if itemData.requirements then
    job:give(commonComponents.Children, {})
    local children = job:get(commonComponents.Children).children
    for selector, amount in pairs(itemData.requirements) do
      local subJob = ECS.Entity()
      subJob:give(commonComponents.Job)
      subJob:give(commonComponents.Name, "FetchJob")
      subJob:give(commonComponents.Item, itemData, selector)
      subJob:give(commonComponents.Parent, job)
      local finishedCallBack = function()
        self:consumeRequirement(job, subJob)
      end
      subJob:give(commonComponents.FetchJob, job, selector, amount, finishedCallBack)
      subJob:apply()
      table.insert(children, subJob)
      self:getInstance():addEntity(subJob)
    end
  end

  job:apply()
  self:getInstance():addEntity(job)
  
  self.jobSystem:addJob(job)

  return job
end

function BluePrintSystem:init(mapSystem, jobSystem)
  self.mapSystem = mapSystem
  self.jobSystem = jobSystem
end

function BluePrintSystem:update(dt) --luacheck: ignore
end

function BluePrintSystem:consumeRequirement(bluePrint, item)
  local bluePrintComponent = bluePrint:get(commonComponents.BluePrintJob)
  bluePrintComponent.materialsConsumed[item:get(commonComponents.Item).selector] = item
end

function BluePrintSystem:isBluePrintReadyToBuild(bluePrint)
  if bluePrint:get(commonComponents.Job).finished then return false end

  local bluePrintComponent = bluePrint:get(commonComponents.BluePrintJob)
  local materialsConsumed = bluePrintComponent.materialsConsumed
  local requirements = bluePrint:get(commonComponents.Item).itemData.requirements

  for selector, item in pairs(requirements) do
    if not materialsConsumed[selector] then
      return false
    end
  end

  return true
end

function BluePrintSystem:bluePrintFinished(bluePrint) --luacheck: ignore
  if bluePrint:has(commonComponents.Draw) then
    local draw = bluePrint:get(commonComponents.Draw)
    draw.color = { 1, 0, 0 }
  end
end

function BluePrintSystem:placeBluePrints(nodes, constructionType, selector)
    for node, count in nodes do
      local gridPosition = self.mapSystem:clampToWorldBounds(Vector(node:getX(), node:getY()))
      if self.mapSystem:isCellAvailable(gridPosition) then
        local bluePrint = self:generateBluePrintJob(gridPosition, constructionType, selector)
        self:getInstance():emit("blueprintActivated", bluePrint)
      end
    end
end

return BluePrintSystem
