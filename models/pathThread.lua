local channelMain, channelThread = ...

require 'love.math'

local universe = require('models.universe')
local lume = require('libs.lume')


while true do

  print("Demanding...")
  local pathFindObject = channelMain:demand()
  print("Got object, ", pathFindObject)
  local newObject = {
    isDone = true,
    result = love.math.random()
  }

  local toNodesToCheck = {}

  local grid = universe.getGrid()
  local finder = universe.getFinder()

  local toNode = grid:getNodeAt(pathFindObject.toX, pathFindObject.toY)

  if pathFindObject.searchNeighbours then
    toNodesToCheck = grid:getNeighbours(toNode)
  end

  table.insert(toNodesToCheck, toNode)

  local path = nil
  for _, node in ipairs(toNodesToCheck) do
    path = finder:getPath(pathFindObject.fromX, pathFindObject.fromY, node:getX(), node:getY())
    if path then
      local path = lume.map(e.path._nodes, function(node) return { x = node._x, y = node._y } end)
      break
    end
  end

  channelThread:push(path or "Path not found")
end
