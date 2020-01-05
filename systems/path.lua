local Vector = require('libs.brinevector')
local universe = require('models.universe')
local PathSystem = ECS.System({ECS.Components.path, ECS.Components.position})


function PathSystem:update(dt)
  for _, entity in ipairs(self.pool) do
    self:processPathFinding(entity)
  end
end

function PathSystem:processPathFinding(entity) --luacheck: ignore
  local pathComponent = entity:get(ECS.Components.path)
  local velocityComponent = entity:get(ECS.Components.velocity)

  velocityComponent.vector = Vector(0, 0)

  if not pathComponent.path then
    return
  end

  local position = entity:get(ECS.Components.position).vector
  local nextGridPosition

  for node, count in pathComponent.path:nodes() do
    if count == pathComponent.currentIndex then
      nextGridPosition = Vector(node:getX(), node:getY())
      break
    end
  end

  if nextGridPosition then
    local nextPosition = universe.gridPositionToPixels(nextGridPosition, "center")
    local angle = math.atan2(nextPosition.y - position.y, nextPosition.x - position.x)
    velocityComponent.vector = Vector(math.cos(angle), math.sin(angle)).normalized

    if universe.pixelsToGridCoordinates(position) == nextGridPosition then
      pathComponent.currentIndex = pathComponent.currentIndex + 1

      if pathComponent.currentIndex == table.getn(pathComponent.path._nodes) then
        self:getWorld():emit("pathFinished", entity)
        -- if pathComponent.path.finishedCallBack then
        --   pathComponent.path.finishedCallBack()
        -- end
        print("Finished so removing path")
        entity:remove(ECS.Components.path)
      end
    end
    velocityComponent.vector = velocityComponent.vector.normalized
  end
end

return PathSystem
