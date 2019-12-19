--local inspect = require('libs/inspect')
local Vector = require('libs/brinevector/brinevector')
local components = require('libs/concord').components

local gridUtils = require('utils/gridUtils')
-- Create a draw System.
local BluePrintSystem = ECS.System("bluePrint", {components.bluePrintJob})

function BluePrintSystem:generateBluePrintJob(gridPosition, itemData, bluePrintItemSelector)
  local job = ECS.Entity()
  job:give(components.job)
  job:give(components.name, "BluePrintJob")
  job:give(components.bluePrintJob)
  job:give(components.sprite, itemData.sprite)
  job:give(components.item, itemData, bluePrintItemSelector)
  job:give(components.position, gridUtils.gridPositionToPixels(gridPosition))
  job:give(components.collision)

  if itemData.requirements then
    job:give(components.children, {})
    local children = job:get(components.children).children
    for selector, amount in pairs(itemData.requirements) do
      local subJob = ECS.Entity()
      subJob:give(components.job)
      subJob:give(components.name, "FetchJob")
      subJob:give(components.item, itemData, selector)
      subJob:give(components.parent, job)
      local finishedCallBack = function()
        self:consumeRequirement(job, subJob)
      end
      subJob:give(components.fetchJob, job, selector, amount, finishedCallBack)
      subJob:apply()
      table.insert(children, subJob)
      self:getWorld():addEntity(subJob)
    end
  end

  job:apply()
  self:getWorld():addEntity(job)
  
  self.getWorld():emit("jobAdded", job)

  return job
end

function BluePrintSystem:init()
end

function BluePrintSystem:update(dt) --luacheck: ignore
end

function BluePrintSystem:consumeRequirement(bluePrint, item)
  local bluePrintComponent = bluePrint:get(components.bluePrintJob)
  bluePrintComponent.materialsConsumed[item:get(components.item).selector] = item
end


function BluePrintSystem:bluePrintFinished(bluePrint) --luacheck: ignore
  if bluePrint:has(components.draw) then
    local draw = bluePrint:get(components.draw)
    draw.color = { 1, 0, 0 }
  end
end

function BluePrintSystem:placeBluePrints(nodes, constructionType, selector)
    for node, count in nodes do
      local gridPosition = gridUtils.clampToWorldBounds(Vector(node:getX(), node:getY()))
      if gridUtils.isCellAvailable(gridPosition) then
        local bluePrint = self:generateBluePrintJob(gridPosition, constructionType, selector)
        self:getWorld():emit("blueprintActivated", bluePrint)
      end
    end
end

return BluePrintSystem
