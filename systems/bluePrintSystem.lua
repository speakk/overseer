local inspect = require('libs/inspect') --luacheck: ignore
local Vector = require('libs.brinevector')

local universe = require('models.universe')
local BluePrintSystem = ECS.System("bluePrint", {ECS.Components.bluePrintJob, ECS.Components.job})

local BluePrint = require('models.jobTypes.bluePrint')


function BluePrintSystem:placeBluePrints(nodes, constructionType, selector)
    for node, _ in nodes do
      local gridPosition = universe.clampToWorldBounds(Vector(node:getX(), node:getY()))
      if universe.isCellAvailable(gridPosition) then
        local job = BluePrint.generate(gridPosition, constructionType, selector)
        if job:has(ECS.Components.children) then
          for _, child in ipairs(job:get(ECS.Components.children).children) do
            self:getWorld():addEntity(child)
          end
        end
        self:getWorld():addEntity(job)
        self:getWorld():emit("jobAdded", job)
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
