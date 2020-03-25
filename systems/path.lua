local Vector = require('libs.brinevector')
local Gamestate = require("libs.hump.gamestate")
local Path = require('libs.jumper.core.path')
local Node = require('libs.jumper.core.node')
local inspect = require('libs.inspect')
local positionUtils = require('utils.position')
local pathFinder = require('models.pathFinder')
local PathSystem = ECS.System({ pool = { "path", "position" } })

function PathSystem:update(dt) --luacheck: ignore
  for _, entity in ipairs(self.pool) do
    self:processPathFinding(entity)
  end
end

function PathSystem:processPathFinding(entity) --luacheck: ignore
  local pathComponent = entity.path
  --print("pathComponent in processPathFinding", entity, pathComponent)
  local velocityComponent = entity.velocity

  velocityComponent.vector = Vector(0, 0)

  if not pathComponent.path then
    if not pathComponent.pathThread and
      love.timer.getTime() - pathComponent.componentAdded > pathComponent.randomDelay then
      local entityPosition = positionUtils.pixelsToGridCoordinates(entity.position.vector)
      pathComponent.pathThread = pathFinder.getPathThread(
        Gamestate.current().map, entityPosition.x, entityPosition.y, pathComponent.toX, pathComponent.toY
      )
    end

    if not pathComponent.pathThread then return end
    --print(inspect(pathComponent.pathThread))
    local err = pathComponent.pathThread.thread:getError()
    if err then print("ERROR", err) end

    local pathNodes = pathComponent.pathThread.channelThread:pop()
    --print("pathNodes", pathNodes)
    if pathNodes and type(pathNodes) ~= "string" then
      local gridPath = Path()
      for _, node in ipairs(pathNodes) do
        gridPath:addNode(Node(node.x, node.y))
      end
      pathComponent.path = gridPath
    end


    if type(pathNodes) == "string" then
      print("Error from pathFind:", pathNodes)
    end
  end

  if not pathComponent.path or pathComponent.finished then
    return
  end


  local position = entity.position.vector

  if not pathComponent.path._nodes then print("Didn't have _nodes!", inspect(pathComponent.path)) end
  local node = pathComponent.path._nodes[pathComponent.currentIndex]

  local nextGridPosition

  if node then
    nextGridPosition = Vector(node:getX(), node:getY())
  end

  local nextPosition = positionUtils.gridPositionToPixels(nextGridPosition, "center", 2)
  local diffVector = (nextPosition - position)
  local length = diffVector.length
  velocityComponent.vector = diffVector.normalized

  if length < 32 then
  --if positionUtils.isInPosition(positionUtils.pixelsToGridCoordinates(position), nextGridPosition) then
    --print("currentIndex", pathComponent.currentIndex, "length:", #pathComponent.path._nodes)
    if pathComponent.currentIndex == #pathComponent.path._nodes then
      self:getWorld():emit("pathFinished", entity)
      pathComponent.finished = true
      return
    end

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
      if not positionUtils.pathStillValid(path) then
        entity:remove("path")
        entity.searched_for_path = false
        print("Path was not valid, setting 'searched_for_path' to false")
      end
    else --luacheck: ignore
      -- Make sure current location is valid
      -- TODO: Uncomment this, please!
      -- local position = entity.position.vector
      -- local gridCoordinates = positionUtils.pixelsToGridCoordinates(position)
      -- if not positionUtils.isCellAvailable(gridCoordinates) then
      --   local newPath = positionUtils.findPathToClosestEmptyCell(gridCoordinates)
      --   if newPath then
      --     entity:give("path", newPath)
      --   end
      -- end
    end

  end
end

return PathSystem
