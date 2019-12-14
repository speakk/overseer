--local inspect = require('libs/inspect')
local Vector = require('libs/brinevector/brinevector')
local commonComponents = require('components/common')
-- Create a draw System.
local BluePrintSystem = ECS.System({commonComponents.BluePrint})

function BluePrintSystem:generateBluePrintJob(gridPosition, itemData, bluePrintItemSelector)
  local job = ECS.Entity()
  job:give(commonComponents.Job)
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
      print("Selector", selector)
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

  return job
end

function BluePrintSystem:init(mapSystem)
  self.mapSystem = mapSystem
end

function BluePrintSystem:update(dt) --luacheck: ignore
end

function BluePrintSystem:consumeRequirement(bluePrint, item)
  print("Consuming requirement!", item:get(commonComponents.Item).selector)
  local bluePrintComponent = bluePrint:get(commonComponents.BluePrintJob)
  bluePrintComponent.materialsConsumed[item:get(commonComponents.Item).selector] = item
end

function BluePrintSystem:isBluePrintReadyToBuild(bluePrint)
  local bluePrintComponent = bluePrint:get(commonComponents.BluePrintJob)
  local materialsConsumed = bluePrintComponent.materialsConsumed
  local requirements = bluePrint:get(commonComponents.Item).itemData.requirements

  for selector, item in pairs(requirements) do
    print("Is materialsConsumed", selector, materialsConsumed[selector])
    if not materialsConsumed[selector] then return false end
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
      print(node, count)
      local gridPosition = self.mapSystem:clampToWorldBounds(Vector(node:getX(), node:getY()))
      if self.mapSystem:isCellAvailable(gridPosition) then
        local bluePrint = self:generateBluePrintJob(gridPosition, constructionType, selector)
        self:getInstance():emit("blueprintActivated", bluePrint)
      end
    end
end

return BluePrintSystem
