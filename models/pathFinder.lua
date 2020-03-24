local pathThreadPool = require('models.pathThreadPool')

local path = {}

function path.getPathThread(map, fromX, fromY, toX, toY)
  local pathThread = pathThreadPool.getPathThread(map, fromX, fromY, toX, toY)
  return pathThread
end

return path
