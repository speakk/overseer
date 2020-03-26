local inspect = require('libs.inspect') --luacheck: ignore
local Vector = require('libs.brinevector')

local positionUtils = require('utils.position')
local BluePrintSystem = ECS.System({pool = {"bluePrintJob", "job"}})

function BluePrintSystem:bluePrintsPlaced(coords, assemblage)
  print("bluePrintsPlaced")
  for _, position in ipairs(coords) do
    if positionUtils.isPositionWalkable(position) then
      local job = ECS.Entity()
        :assemble(assemblage)
        :assemble(ECS.a.jobs.bluePrint, position)
      if job.requirements then
        job:give("children", {})
        local childrenIds = job.children.children
        for selector, amount in pairs(job.requirements.value) do
          local subJob = ECS.Entity():assemble(ECS.a.jobs.fetch, job.id.id, selector, amount)
          subJob:give("parent", job.id.id)
          table.insert(childrenIds, subJob.id.id)
          self:getWorld():addEntity(subJob)
        end
      end
      self:getWorld():addEntity(job)
      --self:getWorld():emit("jobAdded", job)
    end
  end
end

function BluePrintSystem:generateGUIDraw()
  for _, entity in ipairs(self.pool) do
    local progress = entity.bluePrintJob.buildProgress
    if progress <= 0 then return end

    local barSize = Vector(32, 5)
    local position = entity.position.vector
    local offsetPosition = position + Vector(0, 32-barSize.y)
    love.graphics.setColor(0.3, 0.3, 0.4, 1)
    love.graphics.rectangle("fill",
      offsetPosition.x,
      offsetPosition.y,
      barSize.x,
      barSize.y)

    --local progressRectSize = barSize.x/100*progress
    local progressRectSize = barSize.x/100*math.min(progress, 100)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill",
      offsetPosition.x,
      offsetPosition.y,
      progressRectSize,
      barSize.y)

  end
end

function BluePrintSystem:jobFinished(job) --luacheck: ignore
  job:give('active')
end

local buildProgressSpeedModifier = 5
function BluePrintSystem:bluePrintProgress(bluePrintComponent, amount) --luacheck: ignore
  bluePrintComponent.buildProgress = bluePrintComponent.buildProgress + amount * bluePrintComponent.constructionSpeed * buildProgressSpeedModifier --luacheck: ignore
  print("buildProgress now", bluePrintComponent.buildProgress)
end

return BluePrintSystem
