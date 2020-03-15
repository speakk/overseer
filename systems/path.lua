local Vector = require('libs.brinevector')
local Path = require('libs.jumper.core.path')
local Node = require('libs.jumper.core.node')
local inspect = require('libs.inspect')
local universe = require('models.universe')
local pathFinder = require('models.pathFinder')
local PathSystem = ECS.System({ECS.c.path, ECS.c.position})

function PathSystem:update(dt)
  for i, entity in ipairs(self.pool) do
    self:processPathFinding(entity)
  end
end

function PathSystem:processPathFinding(entity) --luacheck: ignore
  local pathComponent = entity.path
  --print("pathComponent in processPathFinding", entity, pathComponent)
  local velocityComponent = entity.velocity

  velocityComponent.vector = Vector(0, 0)

  if not pathComponent.path then
    if not pathComponent.pathThread and love.timer.getTime() - pathComponent.componentAdded > pathComponent.randomDelay then
      local entityPosition = universe.pixelsToGridCoordinates(entity.position.vector)
      pathComponent.pathThread = pathFinder.getPathThread(universe.getMap(), entityPosition.x, entityPosition.y, pathComponent.toX, pathComponent.toY)
      --print("Got thread", pathComponent.pathThread)
    end

    if not pathComponent.pathThread then return end

    local pathNodes = pathComponent.pathThread.channelThread:pop()
    if pathNodes and type(pathNodes) ~= "string" then
      local gridPath = Path()
      for _, node in ipairs(pathNodes) do
        gridPath:addNode(Node(node.x, node.y))
      end
      pathComponent.path = gridPath
    end
  end

  if not pathComponent.path or pathComponent.finished then
    return
  end


  local position = entity.position.vector

  if not pathComponent.path._nodes then print("Didn't have _nodes!", inspect(pathComponent.path)) end
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

  local nextPosition = universe.gridPositionToPixels(nextGridPosition, "center", 2)
  local angle = math.atan2(nextPosition.y - position.y, nextPosition.x - position.x)
  velocityComponent.vector = Vector(math.cos(angle), math.sin(angle)).normalized

  if universe.isInPosition(universe.pixelsToGridCoordinates(position), nextGridPosition) then
    --print("currentIndex", pathComponent.currentIndex, "length:", #pathComponent.path._nodes)
    if pathComponent.currentIndex == #pathComponent.path._nodes then
      self:getWorld():emit("pathFinished", entity)
      pathComponent.finished = true 
      return
    end

    --print("We are in position for the next path node, advance index")
    pathComponent.currentIndex = pathComponent.currentIndex + 1
  end

  --velocityComponent.vector = velocityComponent.vector.normalized
  velocityComponent.vector = velocityComponent.vector
end

-- TODO: THREADING FUCKS THIS UP
function PathSystem:gridUpdated()
  for _, entity in ipairs(self.pool) do
    -- Invalidate paths
    if entity.path and entity.path.path then
      local path = entity.path.path
      if not universe.pathStillValid(path) then
        entity:remove(ECS.c.path)
        entity.searched_for_path = false
        print("Path was not valid, setting 'searched_for_path' to false")
      end
    else
      -- Make sure current location is valid
      -- TODO: Uncomment this, please!
      -- local position = entity.position.vector
      -- local gridCoordinates = universe.pixelsToGridCoordinates(position)
      -- if not universe.isCellAvailable(gridCoordinates) then
      --   local newPath = universe.findPathToClosestEmptyCell(gridCoordinates)
      --   if newPath then
      --     entity:give(ECS.c.path, newPath)
      --   end
      -- end
    end

  end
end

return PathSystem
