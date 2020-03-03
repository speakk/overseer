local universe = require('models.universe')
local pathThreadPool = require('models.pathThreadPool')

local path = {}

function path.getPathThread(map, fromX, fromY, toX, toY)
  local pathThread = pathThreadPool.getPathThread(map, fromX, fromY, toX, toY)
  return pathThread

  --local toNodesToCheck = {}

  --if searchNeighbours then
  --  toNodesToCheck = grid:getNeighbours(toNode)
  --end

  --table.insert(toNodesToCheck, toNode)

  --for _, node in ipairs(toNodesToCheck) do
  --  local path = myFinder:getPath(from.x, from.y, node:getX(), node:getY())
  --  if path then return path end
  --end

  --return nil
end

return path
