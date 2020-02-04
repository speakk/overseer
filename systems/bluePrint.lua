local inspect = require('libs.inspect') --luacheck: ignore
local Vector = require('libs.brinevector')
local entityManager = require('models.entityManager')

local universe = require('models.universe')
local BluePrintSystem = ECS.System({ECS.c.bluePrintJob, ECS.c.job})

local BluePrint = require('models.jobTypes.bluePrint')


function BluePrintSystem:bluePrintsPlaced(nodes, constructionType, selector)
  print("bluePrintsPlaced")
    for node, _ in nodes do
      local gridPosition = universe.clampToWorldBounds(Vector(node:getX(), node:getY()))
      if universe.isCellAvailable(gridPosition) then
        local job, children = BluePrint.generate(gridPosition, constructionType, selector)
        if children then
          for _, child in ipairs(children) do
            --local child = entityManager.get(childId)
            self:getWorld():addEntity(child)
          end
        end
        print("Adding job in bluePrintsPlaced", job)
        self:getWorld():addEntity(job)
        --self:getWorld():emit("jobAdded", job)
      end
    end
end

function BluePrintSystem:generateGUIDraw()
  for _, entity in ipairs(self.pool) do
    local progress = entity:get(ECS.c.bluePrintJob).buildProgress
    if progress <= 0 then return end

    local barSize = Vector(32, 5)
    local position = entity:get(ECS.c.position).vector
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


local buildProgressSpeedModifier = 20
function BluePrintSystem:bluePrintProgress(bluePrintComponent, amount)
  bluePrintComponent.buildProgress = bluePrintComponent.buildProgress + bluePrintComponent.constructionSpeed * buildProgressSpeedModifier
end

return BluePrintSystem
