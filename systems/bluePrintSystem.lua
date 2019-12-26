local inspect = require('libs/inspect')
local Vector = require('libs.brinevector')

local universe = require('models.universe')
local BluePrintSystem = ECS.System("bluePrint", {ECS.Components.bluePrintJob, ECS.Components.job})

function BluePrintSystem:generateBluePrintJob(gridPosition, itemData, bluePrintItemSelector)
  local job = ECS.Entity()
  job:give(ECS.Components.job)
  job:give(ECS.Components.name, "BluePrintJob")
  job:give(ECS.Components.bluePrintJob)
  job:give(ECS.Components.sprite, itemData.sprite)
  job:give(ECS.Components.item, itemData, bluePrintItemSelector)
  job:give(ECS.Components.position, universe.gridPositionToPixels(gridPosition))
  job:give(ECS.Components.collision)


  if itemData.requirements then
    job:give(ECS.Components.children, {})
    local children = job:get(ECS.Components.children).children
    for selector, amount in pairs(itemData.requirements) do
      local subJob = ECS.Entity()
      subJob:give(ECS.Components.job)
      subJob:give(ECS.Components.name, "FetchJob")
      subJob:give(ECS.Components.item, itemData, selector)
      subJob:give(ECS.Components.parent, job)
      local finishedCallBack = function()
        self:consumeRequirement(job, subJob)
      end
      subJob:give(ECS.Components.fetchJob, job, selector, amount, finishedCallBack)
      table.insert(children, subJob)
      self:getWorld():addEntity(subJob)
    end
  end

  self:getWorld():addEntity(job)
  self:getWorld():emit("jobAdded", job)

  return job
end

function BluePrintSystem:consumeRequirement(bluePrint, item) --luacheck: ignore
  local bluePrintComponent = bluePrint:get(ECS.Components.bluePrintJob)
  bluePrintComponent.materialsConsumed[item:get(ECS.Components.item).selector] = item
end

function BluePrintSystem:bluePrintFinished(bluePrint) --luacheck: ignore
  if bluePrint:has(ECS.Components.draw) then
    local draw = bluePrint:get(ECS.Components.draw)
    draw.color = { 1, 0, 0 }
  end
end

function BluePrintSystem:placeBluePrints(nodes, constructionType, selector)
    for node, _ in nodes do
      local gridPosition = universe.clampToWorldBounds(Vector(node:getX(), node:getY()))
      if universe.isCellAvailable(gridPosition) then
        local bluePrint = self:generateBluePrintJob(gridPosition, constructionType, selector)
        self:getWorld():emit("blueprintActivated", bluePrint)
      end
    end
end

function BluePrintSystem:generateGUIDraw()
  for _, entity in ipairs(self.pool) do
    local barSize = Vector(32, 5)
    local position = entity:get(ECS.Components.position).vector
    local offsetPosition = position + Vector(0, 32-barSize.y)
    love.graphics.setColor(0.3, 0.3, 0.4, 1)
    love.graphics.rectangle("fill",
      offsetPosition.x,
      offsetPosition.y,
      barSize.x,
      barSize.y)

    local progress = entity:get(ECS.Components.bluePrintJob).buildProgress
    local progressRectSize = barSize.x/100*progress
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill",
      offsetPosition.x,
      offsetPosition.y,
      progressRectSize,
      barSize.y)

  end
end

return BluePrintSystem
