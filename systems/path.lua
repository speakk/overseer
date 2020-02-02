local Vector = require('libs.brinevector')
local universe = require('models.universe')
local PathSystem = ECS.System({ECS.c.path, ECS.c.position})


function PathSystem:update(dt)
  for i, entity in ipairs(self.pool) do
    self:processPathFinding(entity)
  end
end

function PathSystem:processPathFinding(entity) --luacheck: ignore
  local pathComponent = entity:get(ECS.c.path)
  local velocityComponent = entity:get(ECS.c.velocity)

  velocityComponent.vector = Vector(0, 0)

  if not pathComponent.path then
    return
  end

  local position = entity:get(ECS.c.position).vector

  local node = pathComponent.path._nodes[pathComponent.currentIndex]

  local validNode = true
  local nextGridPosition

  if not node then
    validNode = false
  else
    nextGridPosition = Vector(node:getX(), node:getY())
  end

  if not nextGridPosition then
    validNode = false
  end

  -- TODO: Proper handling of invalid path
  if not validNode then
    print("Something went wrong, no valid node next")
    entity:remove(ECS.c.path)
    --pathComponent.finished = true 
    return
  end


  --for node, count in pathComponent.path:nodes() do
  --  if count == pathComponent.currentIndex then
  --    nextGridPosition = Vector(node:getX(), node:getY())
  --    break
  --  end
  --end

  local nextPosition = universe.gridPositionToPixels(nextGridPosition, "center")
  local angle = math.atan2(nextPosition.y - position.y, nextPosition.x - position.x)
  velocityComponent.vector = Vector(math.cos(angle), math.sin(angle)).normalized

  --if universe.pixelsToGridCoordinates(position) == nextGridPosition then
  if universe.isInPosition(universe.pixelsToGridCoordinates(position), nextGridPosition) then
    if pathComponent.currentIndex == #pathComponent.path._nodes then
      self:getWorld():emit("pathFinished", entity)
      -- if pathComponent.path.finishedCallBack then
      --   pathComponent.path.finishedCallBack()
      -- end
      print("Finished so removing path")
      pathComponent.finished = true 
      --entity:remove(ECS.c.path)
    end

    pathComponent.currentIndex = pathComponent.currentIndex + 1
  end
  velocityComponent.vector = velocityComponent.vector.normalized
end

return PathSystem
