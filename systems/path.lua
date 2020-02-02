local Vector = require('libs.brinevector')
local universe = require('models.universe')
local PathSystem = ECS.System({ECS.c.path, ECS.c.position})

function PathSystem:update(dt)
  for i, entity in ipairs(self.pool) do
    self:processPathFinding(entity)
  end
end

function PathSystem:processPathFinding(entity) --luacheck: ignore
  love.mouse.setGrabbed(true)
  local pathComponent = entity:get(ECS.c.path)
  local velocityComponent = entity:get(ECS.c.velocity)

  if not pathComponent.path or pathComponent.finished then
    return
  end

  velocityComponent.vector = Vector(0, 0)

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

  -- -- TODO: Proper handling of invalid path
  -- if not validNode then
  --   print("Something went wrong, no valid node next")
  --   --entity:remove(ECS.c.path)
  --   pathComponent.finished = true 
  --   return
  -- end

  --local nextPosition = universe.gridPositionToPixels(nextGridPosition, "center")
  local nextPosition = universe.gridPositionToPixels(nextGridPosition, "center", 2)
  local angle = math.atan2(nextPosition.y - position.y, nextPosition.x - position.x)
  velocityComponent.vector = Vector(math.cos(angle), math.sin(angle)).normalized

  --if universe.pixelsToGridCoordinates(position) == nextGridPosition then

  if universe.isInPosition(universe.pixelsToGridCoordinates(position), nextGridPosition) then
    print("currentIndex", pathComponent.currentIndex, "length:", #pathComponent.path._nodes)
    if pathComponent.currentIndex == #pathComponent.path._nodes then
      self:getWorld():emit("pathFinished", entity)
      print("Finished so removing path")
      pathComponent.finished = true 
      return
    end

    print("We are in position for the next path node, advance index")
    pathComponent.currentIndex = pathComponent.currentIndex + 1
  end

  --velocityComponent.vector = velocityComponent.vector.normalized
  velocityComponent.vector = velocityComponent.vector
end

return PathSystem
