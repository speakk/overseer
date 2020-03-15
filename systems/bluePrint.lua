local inspect = require('libs.inspect') --luacheck: ignore
local Vector = require('libs.brinevector')
local entityManager = require('models.entityManager')

local universe = require('models.universe')
local BluePrintSystem = ECS.System({ECS.c.bluePrintJob, ECS.c.job})

local BluePrint = require('models.jobTypes.bluePrint')


function BluePrintSystem:bluePrintsPlaced(coords, constructionType, selector)
  print("bluePrintsPlaced")
    for _, position in ipairs(coords) do
      --local gridPosition = universe.clampToWorldBounds(Vector(node:getX(), node:getY()))
      if universe.isCellAvailable(position) then
        local job, children = BluePrint.generate(position, constructionType, selector)
        if children then
          for _, child in ipairs(children) do
            --local child = entityManager.get(childId)
            self:getWorld():addEntity(child)
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

    local progressRectSize = barSize.x/100*progress
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill",
      offsetPosition.x,
      offsetPosition.y,
      progressRectSize,
      barSize.y)

  end
end


local buildProgressSpeedModifier = 5
function BluePrintSystem:bluePrintProgress(bluePrintComponent, amount)
  bluePrintComponent.buildProgress = bluePrintComponent.buildProgress + amount * bluePrintComponent.constructionSpeed * buildProgressSpeedModifier
  print("buildProgress now", bluePrintComponent.buildProgress)
end

return BluePrintSystem
